## Version 0.3.9

* .vimrc inside containers

## Version 0.3.8

* Enable root login with a password when not running in EC2

## Version 0.3.7

* Use the configured setting for master hostname in config files on containers

## Version 0.3.6

* Allow password based logins for students.  Useful for EC2 Instances.

## Version 0.3.5

* Installs course_selector tool into containers

## Version 0.3.3
* Profile for AMD course

## Version 0.3.2
* Fixes environment path for 2015.2

## Version 0.3.1
* Add support for Puppet 4 parser course

## Version 0.2.3
* Validate usernames

## Version 0.2.2
* Adding wrapper for first_module course

## Version 0.2.1

* Makes MAP_ENVIRONMENTs optional
  * use true for intro
  * use false for classes where puppetcode is managed by classroom module.
* SystemD working inside centosagent containers
* Fixes delete api endpoint to completely delete user/container
