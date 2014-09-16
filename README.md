PuppetFactory
=============

## Classroom automation for the Intro to Puppet course

The Intro course is designed to be a quickly paced very high level overview of
the capabilities and concepts of Puppet Enterprise. It's intended for technology
decision makers or managers who don't actually need to *use* Puppet Enterprise
on a regular basis, but need to know what it does and how it works.

Walking them through a complex installation process is counterproductive.
Requiring them to manage their own virtual machine and debug networking issues
takes up a great deal of classroom time.

This project is intended to eliminate that need. Each student receives a simulated
Puppet Enterprise environment that is sandboxed into a standard Unix user home
directory. An MCollective server is configured for each user, allowing Live
Management exercises to work properly, and custom providers have been written
for certain core types allowing them to work seamlessly in rootless mode.

## Resource types implemented

Students may freely use the following types in their Puppet manifests.

* `host`
* `package`
* `user`
* `service`
* `file` (only files the user has permissions to)

## Dependencies

The classroom depends on the following external tools, which are bundled in the
`/files` directory:

### Doppelganger gem

This gem provides a simple library and command line tools for working with the
rootless resource management databases. This library is used by the providers
in the `puppetfactory` gem.

### PuppetFactory gem

This is the actual graphical Web UI allowing the students to interact with the
system. It allows students to create their own user account and provides a tab
for an SSH console login.

## Usage

1. Start with a standard Puppetlabs Training VM
1. Configure it as `master.puppetlabs.vm` and install PE.
1. `puppet module install pltraining/puppetfactory`
1. Classify the master only (not default) with `puppetfactory`.
1. Run Puppet a few times to ensure that MCollective is completely configured.
1. Load up [http://${ipaddress}](http://${ipaddress}) in a browser.
1. Write the URL on the board and start class.

*Note*: a UTF encoding issue currently requires two Puppet runs to get the gems
installed properly. This is only cosmetic.

Students will need to use the _Users_ tab to create their accounts. This tab
will also list all known users along with statuses, including useful information
about their accounts; certname, Console login, etc.

They can use their username to SSH to the master, either from their own client
or from the _SSH Login_ tab. Their Console login will use the same password.

## Behind the scenes

### Providers:

* `host`
    * This provider uses `~/etc/hosts` for its host records.
* `package`, `user`, `service`
    * Doesn't actually manage resources.
    * Simulates resource management by recording values in a database file.
      * `~/etc/packages.yaml`
      * `~/etc/users.yaml`
      * `~/etc/services.yaml`

### Command line tools.

* `pl-package`
* `pl-user`
* `pl-service`

User documentation is provided on the _Reference_ tab.

### Puppet configuration

The agent is configured by the user's `~/.puppet` directory. This is symlinked
to `~/puppet` for convenience. The user's environment is set to their own username
and the master's modulepath and manifest are configured to look in the user's
home directory. The result is that the user installation will behave mostly as
though it is a complete Puppet Enterprise standalone installation.

An Agent daemon is *not started* per user, but the user can run the agent by
hand with `puppet agent -t` or `puppet apply`.

### MCollective configuration

Each user's `~/etc/mcollective` directory is copied from the system-wide
`/etc/puppetlabs/mcollective` with customization to `server.cfg` (per-user
identity, log locations, etc.). This does mean that they are all reusing the
same certificates which does not appear to cause a problem.

Live Management is able to interact with that user's Puppet Agent (enable,
disable, runonce, etc.) and can use the RAL to browse and modify the user's
simulated hosts, packages, users, and services.
