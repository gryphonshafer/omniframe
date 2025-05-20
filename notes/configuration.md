# Application Configuration

An application's configuration is handled via a file or files loaded by
[Config::App](https://metacpan.org/pod/Config::App). This is typically the
`~/config/app.yaml` file relative to this framework's root directory and
possibly and likely a `~/config/app.yaml` file relative to the application
project's root directory.

As per [Config::App](https://metacpan.org/pod/Config::App) documentation, there
may be a
[`preinclude`](https://metacpan.org/pod/Config::App#Optional-Configuration-File-Including)
and/or
[`optional_include`](https://metacpan.org/pod/Config::App#Pre-Including-Configuration-Files)
setting in a project's configuration.

## Configuration Notes

Note that in several locations within the configuration, you may see reference
to a `~/local` directory. This is a directory usually auto-created that will
contain generated data, including but not limited to database files and compiled
templates.

Some default settings found in the framework's settings file should be
overwritten in projects when in development mode and set back to their original
states for production mode. This can be accomplished a few different ways, but
the common way is to set the development mode value via a project's settings
under the `default` top-level node, then set the production mode value via a
different top-level node named via a production server name and/or environment
variable.

## Configuration Components

While there could be many project-specific configuration components, the
following are framework defaults:

`mojo_app_lib`
: This is the controller for the project. It should be automatically set by
`~/tools/build_app.pl`.

`database`
: These settings are for the application's database and should be
self-explanatory. By default, SQLite is used.

`logging`
: These settings control application logging within controllers, models, and
tools. In particular for project settings, you'll want to override `alert_email`
and likely `filter` (turning it off).

`template`
: These settings handle
[Template::Toolkit](https://metacpan.org/pod/Template::Toolkit) template
processing. The assumption is that single pages exist in the `pages` directory
with a naming structure that typically maps to their corresponding controller
names. The `components` directory contains templates used in multiple `pages`.
And `email` are email templates.

`packer`
: [HTML::Packer](https://metacpan.org/pod/HTML::Packer) settings.

`sass`
: Omniframe::Class::Sass settings.

`mojolicious`
: Mojolicious and Mojolicious-related settings.
`ws_inactivity_timeout` is a websocket inactivity timeout in seconds.
`linda` contains [MojoX::Linda](https://metacpan.org/pod/MojoX::Linda) settings.
`csrf` contains
[Mojolicious::Plugin::CSRF](https://metacpan.org/pod/Mojolicious::Plugin::CSRF)
settings.
The remainder are either specific Mojolicious settings or self-explanatory.

`email`
: These are universal email settings, typically for emails sent from the `emails`
templates space. In particular for project settings, you'll want to override
`from` and likely `active` in development mode.

`bcrypt`
: These are the default values used when bcrypting. See Omniframe::Util::Bcrypt
for more information.

`crypt`
: These are the default values used when encrypting and/or decrypting. See
Omniframe::Util::Crypt for more information.

`otpauth`
: These are the settings for OTP 2FA. See Omniframe::Class::OTPAuth for more
information.
