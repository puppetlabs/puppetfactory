Doppelganger
============

A simplistic non-root user/package/service management simulation.

All this does is provide a quick library and some tools to interact with
stupid-simple resource databases to simulate working with resources that
typically requires root access. It's designed for use with the Puppet Labs
Introduction to Puppet training class and has providers enabling the use
of this simulation with the standard Puppet Resource Abstraction Layer.

Installation
=============

* Install using the same RubyGems installation that Puppet is using.
    * `/opt/puppet/bin/gem install doppelganger`
* Install the corresponding Puppet module
    * `puppet module install pltraining/doppelganger`

Usage
=============

* Package Management Simulation
  * `pl-packages list`
  * `pl-packages install <package>`
  * `pl-packages uninstall <package>`
* User Management Simulation
  * `pl-user list`
  * `pl-user create <user> [-d <homedir>] [-s <shell>] [-g <group>]`
  * `pl-user modify <user> [-d <homedir>] [-s <shell>] [-g <group>]`
  * `pl-user delete|remove <user>`
* Service Management Simulation
  * `pl-service list`
  * `pl-service start|stop <service>`
  * `pl-service enable|disable <service>`
* Using the Puppet RAL
  * Puppet will automatically select the proper provider, so usage should be transparent.
  * For debugging, you can manually specify the `classroom` provider when managing packages, users, or services.
