PuppetFactory
=============

## Customizable user account management.

Walking students through the PE installation process is counterproductive.
Requiring them to manage their own virtual machine and debug networking issues
takes up a great deal of classroom time.

This project was designed to eliminate that need. Students can create user
accounts with the click of a button, allowing them to work along with exercises
without the overhead of managing a full VM.

Puppetfactory is pluggable and highly configurable. By default, it provides just
a user account and a standard shell login embedded in a web page. Add in the
Docker plugin and that user account then logs into a container. Add in the
Classification plugin and PE Console node groups and classification rules will
be managed automatically. Add in either the R10k or CodeManager plugin and
sources will be managed, allowing the user to deploy a codebase from a
control repository.

The accompanying `pltraining/puppetfactory` Puppet module will build a Docker
image suitable for fully comprehensive Puppet agent nodes and stand up the
components of the Puppetfactory stack.

Users should have their shell set to `pfsh`, which is located in `/usr/local/bin`
by default. It will request the current session ID, and then invoke the `login`
action of whichever plugin is currently configured.

![Screenshot](screenshot.png)

## Usage

### Puppet training classes

If this is being used for a Puppet training class, each course should have a
`pltraining/classroom` profile associated with it. The module should be
installed into the global modulepath

1. Start with a standard Puppetlabs Training Master VM
1. `puppet module install pltraining/classroom --modulepath /etc/puppetlabs/code/modules`
1. Classify the master with `classroom::course::<name>`.
1. Load up [http://${ipaddress}](http://${ipaddress}) in a browser.
1. Write the URL on the board and start class.

Students will need to use the _Users_ tab to create their accounts. This tab
will also list all known users along with statuses, including useful information
about their accounts; certname, Console login, etc.

They can use their username to SSH to the master, either from their own client
or from the _SSH Login_ tab. Their Console login will use the same password.

### Other usage

Run `puppetfactory configprint` to get a printout of all the configuration
settings. If no config file exists, this will be all the default options. To
change any of the options, add them to the `/etc/puppetfactory/config.yaml`
config file.

Most of the options are self explanatory. Some that you may want to configure
include:

* `:port`
    * The port number to listen on.
* `:bind`
    * Which interface to bind to. The default of `0.0.0.0` means bind to all.
* `:user`
    * The username for admin level access.
* `:password`
    * The password for admin level access.
* `:session`
    * The session ID used to create accounts or log in.

Container options:

* `:puppetcode`
    * The path to a folder mapped into the user's container.
* `:modulepath`
    * How the user's modulepath should be mounted.
    * Valid options: `:readwrite`, `:readonly`, or `:none`

Code management options:

* `:gitserver`, `:gituser`, `:controlrepo`
    * The URL to the git server where the control repo lives.
    * The username owning the control repo.
    * The name of the control repo
* `:repomodel`
    * Whether the students will maintain prefixed forks of the control repo or work in branches.
    * Valid options: `:single`, `:peruser`


#### Enabling plugins

Enable plugins to configure how Puppetfactory works by adding them to the `:plugins` option:

    :plugins:
    - :Certificates
    - :Classification
    - :Docker
    - :Logs
    - :Dashboard
    - :CodeManager
    - :ShellUser

List of current plugins:

* `:Certificates`
    * Removes signed certificates when the user is removed.
* `:Classification`
    * Manages PE Console node groups and classification rules for each user.
* `:CodeManager`
    * Manages Code Manager sources for each user.
    * Deploys code into each user's environment.
* `:ConsoleUser`
    * Creates a PE Console user account for each user.
* `:Dashboard`
    * Spec testing dashboard shows current progress through labs.
    * Only enabled for a limited number of classes.
    * Configure with:
      * `:dashboard_path`
          * Where the spec tests reside.
      * `:dashboard_interval`
          * How often the dashboard should update in seconds.
* `:Docker`
    * Manages Docker containers for users.
    * Configure with:
      * `:container_name`
          * The name of the image to build containers from.
          * Defaults to 'centosagent'
      * `:privileged`
          * Whether containers should start in privileged mode.
          * Currently required for `systemd`.
* `:Gitlab`
    * Manages Gitlab accounts for users.
    * Expects a default Gitlab container to be running.
* `:Hooks`
    * Run hook scripts on user creation and deletion.
    * Configure with:
      * `:hooks_path`
          * Path to the hook scripts.
* `:LoginShell`
    * When enabled, logging in with `pfsh` will run the system shell.
* `:Logs`
    * Adds a tab displaying the Puppetfactory logfile.
* `:R10k`
    * Manages `r10k` sources for each user.
    * Deploys code into each user's environment.
* `:ShellUser`
    * Mananges system accounts for each user.
    * Required for any plugins expecting to set user permissions or map directories.
* `:UserEnvironment`
    * When not using a control repo, this will create a default Puppet environment.


### Extending Puppetfactory with plugins

Puppetfactory's plugin model is simple. Each time an action is called, that action
is invoked on each plugin that exposes it. That means that if your plugin has a
method named `create`, then it will be invoked with two arguments, (the new user's
*username* and *password*) each time a new user is created.

Plugins are sorted by their `weight` property, low to high. The default weight is
100, and the `ShellUser` weight is 1, indicating that it should run first when enabled.

See the `Example` plugin in `lib/puppetfactory/plugins/example.rb` for an
explanation of each action. The plugin class name must match the filename, where
the class name is `CamelCased` and the file is `snake_cased`.

Plugins can also add new tabs and new web routes. See the `Logs` plugin for a
simple example of that.


### Components

Several components and services work together to make up the Puppetfactory
stack.  It's recommended to use the `pltraining/puppetfactory` module to manage
the full stack.

#### PuppetFactory gem

This is the actual graphical Web UI allowing the students to interact with the
system. It allows students to create their own user account and provides a tab
for an SSH console login.

#### Abalone

This is the web terminal embedded in the SSH console tab.

#### Nginx

This is used to proxy the services into a cohesive whole, including exposing
HTTP for each student container if configured to do so.

#### Docker

The default container service used by Puppetfactory. This provides students full
root access to their own Puppet agent node.


## Troubleshooting and recovery

Because we're using docker containers for the student environments there are a
few things you can do to troubleshoot.

Run `puppetfactory --help` on the master to see commands to create, remove, or
repair user accounts.

If you need to access a student environment:

* `su - #{username}`

To interact directly with a container (assuming the Docker plugin):

* `docker start #{username}`
* `docker stop #{username}`
* `docker info #{username}`

The containers also have valid init scripts so they can be start/stopped with:

* `systemctl start docker-#{username}`
* `systemctl stop docker-#{username}`


## RESTlike usage

Users can be created by treating the classroom manager like a RESTful API:

* `curl --data 'username=fooh&password=bar' admin:admin@localhost/new`

There are also the following RESTful API endpoints:

* `GET /api/users`
    - The current users with container status
* `GET /api/users/:username`
    - Same as users but only the user indicated
* `GET /api/users/:username/port`
    - The port on the host which is mapped to port 80 on the container
* `GET /api/users/:username/node_group_status`
    - Status of the PE node group
* `GET /api/users/:username/consoe_user_status`
    - Status of the PE console user
* `POST /api/users`
    - Create a new user, container, node group, and console user
* `DELETE /api/users/:username`
    - Remove all trace of the user, container, etc.

Note: These are mostly intended for use in a future UI, but they can be helpful for troubleshooting.


## Acknowledgements

Special thanks to Britt Gresham for the inspiration for this project:
https://github.com/demophoon/webvim
