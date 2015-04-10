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
Puppet Enterprise environment that is sandboxed in a docker container. An 
MCollective server is configured for each user, allowing Live Management 
exercises to work properly, and custom providers have been written for certain 
core types allowing them to work seamlessly in rootless mode.

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

As students create accounts in the puppetfactory UI, docker provisions containers
tagged with the student's username. Accounts, groups, and environments on the 
enterprise console are also created for each user. Each student's environment on
the master is mapped to the /puppetcode directory inside their docker container.
When they log in to the master via shellinabox or SSH with their credentials 
their session is passed into their docker container. From the students perspective
they are on a seperate machine running as root.

## RESTlike usage

Users can be created by treating the classroom manager like a RESTful API:
  curl --data 'username=fooh&password=bar' admin:admin@localhost/new

## Troubleshooting and recovery

Because we're using docker containers for the student environements there are a
few things you can do to troubleshoot.

If you need to access a student enviroment:
`docker exec -i -t #{username} bash`

To trigger a puppet run on a student node:
`docker exec #{username} puppet agent -t`

To start a container that has been stopped (e.g. after a reboot):
`docker start #{username}`

## Acknowledgements

Special thanks to Britt Gresham for the inspiration for this project:
https://github.com/demophoon/webvim
