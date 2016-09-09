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
