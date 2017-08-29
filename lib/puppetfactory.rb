#! /usr/bin/env ruby

require 'rubygems'
require 'sinatra/base'
require 'webrick'
# require 'webrick/https'
# require 'openssl'
require 'resolv'
require 'json'
require 'fileutils'
require 'erb'
require 'yaml'
require 'time'
require 'docker'
require 'rest-client'
require 'open3'

class Puppetfactory < Sinatra::Base
  require 'puppetfactory/helpers'
  require 'puppetfactory/monkeypatches'
  require 'puppetfactory/plugins'

  set :views, File.dirname(__FILE__) + '/../views'
  set :public_folder, File.dirname(__FILE__) + '/../public'
  set :erb, :trim => '-'

  configure :production, :development do
    enable :logging
    use Rack::Session::Cookie, 
      :key          => 'puppetfactory.session',
      :path         => '/',
      :expire_after => 2592000, # In seconds
      :secret       => 'some_secret'
  end

  before do
    # IE is cache happy. Let's make that go away.
    cache_control :no_cache, :max_age => 0
  end
  
  def initialize(app=nil)
    super(app)

    # lets us pretend that the settings object is a hash in our plugins
    def settings.[](opt)
      settings.send(opt) if settings.respond_to? opt
    end

    # Add a link back to the server so that plugins can add routes
    def settings.puppetfactory
      self
    end

    @loaded_plugins = settings.plugins.map do |plugin|
      require "puppetfactory/plugins/#{plugin.snake_case}"
      Puppetfactory::Plugins::const_get(plugin).new(settings)
    end
    @loaded_plugins = @loaded_plugins.sort_by { |plugin| plugin.weight }

    ensure_single_action(:users)
    ensure_single_action(:login)
#    ensure_single_action(:deploy) # TODO: maybe this shouldn't be limited like this.
                                  #       But if not, we need a plugin.suitability() method.
  end

  # UI tab endpoints
  get '/' do
    @tabs = merge(plugins(:tabs, privileged?))
    @existinguser = session.include? :username

    erb :index
  end

  get '/users' do
    @users   = load_users()
    @current = merge(plugins(:userinfo, session[:username], true)) if session.include? :username

    erb :users
  end

  get '/shell' do
    erb :shell
  end
  # End UI tabs

  # set the currently active user. This should probably be a PUT action.
  get '/users/active/:username' do |username|
    session[:username] = username
    {"status" => "ok"}.to_json
  end

  # admin login
  get '/admin-login' do
    protected!
    redirect '/'
  end

  get '/admin-logout' do
    remove_privileges!
    redirect '/'
  end

  # create a new username with the default password.
  get '/new/:username' do |username|
    protected!
    create(username)
  end

  post '/new' do
    confined!
    session[:username] = params[:username]
    create(params[:username], params[:password])
  end

  get '/shell/login' do
    redirect "http://#{request.host}:4200"
  end

  get '/port/:port/' do |port|
    redirect "http://#{request.host}:#{port}"
  end

  # RESTful API endpoints
  # Return details for all users as JSON
  get '/api/users' do
    load_users(true).to_json
  end

  # create a user
  post '/api/users' do
    # no need for all the returned status. That was a workaround for not having any real logging
    create(params[:username], params[:password])
  end

  # Return details for single user
  get '/api/users/:username' do
    username = params[:username]
    load_user(username).to_json
  end

  # perform an action on a given user
  put '/api/users/:username' do |username|
    case params[:action]
    when 'deploy'
      resp = plugins(:deploy, username)

    when 'redeploy'
      resp = plugins(:redeploy, username)

    when 'repair'
      resp = plugins(:repair, username)

    when 'select'
      session[:username] = username
      resp = [true]

    else
      raise "Unknown user action: #{params[:action]}."
    end
    if resp.select { |response| response == false }.size == 0
      {"status" => "success"}.to_json
    else
      {"status" => "failure"}.to_json
    end
  end

  # delete a user
  delete '/api/users/:username' do
    delete(params[:username])
  end


# These endpoints don't seemed to be used for anything
#   get '/api/users/:username/port' do
#     user_port(params[:username])
#   end
#
#   get '/api/users/:username/node_group_status' do
#     node_group_status(params[:username]).to_json
#   end
#
#
#   get '/api/users/:username/console_user_status' do
#     console_user_status(params[:username]).to_json
#   end


  not_found do
    halt 404, 'page not found'
  end

  helpers do
    # call a method of a single named plugin.
    def plugin(name, action, *args)
      plugin = @loaded_plugins.find {|plugin| plugin.class.name == "Puppetfactory::Plugins::#{name.to_s}" }
      plugin.send(action, *args)
    end

    # call a method on all plugins that implement it
    def plugins(action, *args)
      @loaded_plugins.map do |plugin|
        next unless plugin.respond_to? action

        plugin.send(action, *args)
      end.compact
    end

    # call a method on all plugins that implement it
    def reversedplugins(action, *args)
      @loaded_plugins.reverse.map do |plugin|
        next unless plugin.respond_to? action

        plugin.send(action, *args)
      end.compact
    end

    def ensure_single_action(action)
      resp = @loaded_plugins.select { |plugin| plugin.respond_to? action }
      raise "The #{action} action is not exposed by any plugins" if resp.size == 0
      raise "The #{action} action is exposed by multiple loaded plugins! (#{resp.map {|p| p.class }})" unless resp.size == 1
    end

    def action_enabled?(action)
      resp = @loaded_plugins.select { |plugin| plugin.respond_to? action }
      resp.size != 0
    end

    # Take an array of hashes and squash them into a single hash.
    # Keys later in the list override those which come earlier
    def merge(elements)
      elements.inject({}) do |memo, element|
          memo.merge! element
      end
    end



    def create(username, password = 'puppetlabs')
      begin
        responses = plugins(:create, username, password)
        errors    = responses.select { |response| response == false }.size

        if errors == 0
          { :status => :success, :message => "Created user #{username}."}.to_json
        else
          # TODO: should we call delete to cleanup?
          #plugins(:delete, username) # Don't leave artifacts.
          { :status => :failure, :message => "There were #{errors} errors creating #{username}. See logs for details."}.to_json
        end
      rescue => e
        $logger.warn e.backtrace
        {:status => :failure, :message => "Fatal error creating #{username}: #{e.message}"}.to_json
      end
    end

    def delete(username)
      begin
        responses = reversedplugins(:delete, username)
        errors    = responses.select { |response| response == false }.size

        if errors == 0
          { :status => :success, :message => "Deleted user #{username}."}.to_json
        else
          { :status => :failure, :message => "There were #{errors} errors deleting #{username}. See logs for details."}.to_json
        end
      rescue => e
          {:status => :failure, :message => "Fatal error deleting #{username}: #{e.message}"}.to_json
      end
    end

    def load_users(extended = false)
      users = {}
      plugins(:users).flatten.each do |username|
        users[username] = merge(plugins(:userinfo, username, extended))
      end
      users
    end


    # Basic auth boilerplate
    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def confined!
      unless params[:session] == settings.session
        throw(:halt, [403, "Only classroom members are allowed to create accounts!\n"])
      end
    end

    def privileged?
      session[:privileges] == 'admin'
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)

      if @auth.provided? && @auth.basic? && @auth.credentials == [settings.user, settings.password]
        session[:privileges] = 'admin'
        true
      else
        remove_privileges!
        false
      end
    end

    def remove_privileges!
      session.delete :privileges
    end

  end
end
