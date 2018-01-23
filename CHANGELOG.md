# v0.6.4
* Corrected some UI artifacts.
* Display username in alternate login section.
* Add upstream parameter for Gitea configuration.
* Restored *deploy* button spinner.
* Restored missing Gitviz tab.

# v0.6.3
* Set server timeout property correctly
* UI/UX fixes
* Fixed user login/logout issues
* Upgrade JQuery to Latest stable

# v0.6.2
* Correct user login crasher

# v0.6.1
* Fix user selection bug
* Ensure that the gitea admin's .ssh directory exists

# v0.6.0
* Major UI overhaul--single page interface for users
* More robust user management
* Remove race conditions with Gitea integration
* Made it much less likely for users to get raw html error dialogs when provisioning
* Removed some minor shell injection vulnerabilities
* Stopped mapping the yum repo directory, so no more extraneous permission changes from pe_repo

# v0.5.9
* Add link to Gitea when enabled
* Correct caching issue with IE preventing users from deploying code
* Corrected bug causing user sessions to be lost
* Minor style changes

# v0.5.8
* Map additional directories into container for local yum cache

# v0.5.7
* Split puppet module from gem and rearrange repo
* Vendor jruby for offline
* Improved styling

# v0.5.6
* Parameterized the gitea plugin for all virtual courses
* Remove some non-student users from the user list

# v0.5.5
* Treeview plugin view
* Set UsePAM to 'yes' for ssh server
* Friendlier names for student environment groups

# v0.5.4
* gitea support
* Improved dashboard code
* Minor bugfixes

# v0.5.2
* Use full fqdn instead of just the hostname.
* Rescue puppetclassify errors.

# v0.5.1
* Sanitize user environment for CLI tools we use
* Don't create sources when running in a single control repo

# v0.5.0
Moved to using the code-staging directory for everything. Rather than editing
code live, this expects users to edit the code-staging directory and then
deploy via the button.

* Live puppet code-editing disabled.
* Use code-staging to edit code, and then push-button deploy!
* Improved 404 and 50x error pages


# v0.4.0

This is a major refactoring. It's marked as a Y release due to the internal
architecture changing so much, indicating a higher likelihood of errors. It
should not actually be a breaking change.

This adds the plugin system allowing us to reconfigure Puppetfactory for the
different ways we use it. It also adds a few new features, like a *Logs* tab
and the ability to manage code deployments directly from the UI.

This should simplify class setup drastically, as there's no more need for
creating user branches or webhook configuration.

This also marks the first **public release** of the tool, so yay!
