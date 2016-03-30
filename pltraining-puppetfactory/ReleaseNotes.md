## Version 0.4.8

* cli commands for Fundamentals r10k manipulation
* improved stability of dashboard
* use 'training' user instead of 'centos'
* wget installed inside containers
* improved documentation

## Version 0.4.6

* Fix default class name

## Version 0.4.6

* Cleaned up home page slightly

## Version 0.4.5

* Correct duplicate parameter in showoff profile.
* Add hiera profile class.

## Version 0.4.4

* Added the Showoff stack to all class profiles

## Version 0.4.2

* Gitlab support

## Version 0.4.3

Add missing arusso/stunnel dependency

## Version 0.4.2

Flesh out Showoff presentations with PDF generation and secure presentations.

## Version 0.4.1

* Virtual Fundamentals profile
* Manage Showoff presentations
* wetty and dashboard fixes
* Fix for high CPU usage and console corruption
* Support Docker 1.5.0

## Version 0.4.0

* Instructor dashboard
* Wetty for web terminal instead of shellinabox

## Version 0.3.10

* lynx installed inside containers

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
