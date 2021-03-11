package Omniframe::Role::Conf;

use exact -role, -conf;

class_has conf => conf;

1;

=head1 NAME

Omniframe::Role::Conf

=head1 SYNOPSIS

    package Package;

    use exact -class;

    with 'Omniframe::Role::Conf';

    sub root_dir ($self) {
        return $self->conf->get( qw( config_app root_dir ) );
    }

=head1 DESCRIPTION

This role provides a single C<conf> class attribute which is an application-wide
singleton L<Config::App> object with the application's configuration.

=head1 CLASS ATTRIBUTES

=head2 conf

This class attribute, when accessed, will become an application-wide singleton
L<Config::App> object with the application's configuration. The application's
entry-point configuration file is expected to be the C<~/config/app.yaml> file.
Within this file, subsequent includes supported by L<Config::App> can be set.
