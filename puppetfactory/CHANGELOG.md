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
