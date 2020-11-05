package Omniframe::Util::Sass;

use exact 'Omniframe';
use IPC::Run3 'run3';
use Mojo::File 'path';

with 'Omniframe::Role::Conf';

has mode => sub ($self) {
    return $ENV{MOJO_MODE} || $ENV{PLACK_ENV} || 'development';
};

has scss_src => sub ($self) {
    my $scss_src  = $self->conf->get( qw( sass scss_src ) );
    my $root_dir  = $self->conf->get( qw( config_app root_dir ) );
    my $omniframe = $self->conf->get('omniframe') || '';

    return join( "\n",
        map { "\@import '$_';" }
        grep { defined }
        map {
            my $app_file  = "$root_dir/$_";
            my $omni_file = "$root_dir/$omniframe/$_";

            ( -f $app_file or not $omniframe ) ? $app_file  :
            ( -f $omni_file )                  ? $omni_file : undef;
        } ( ref $scss_src eq 'ARRAY' ) ? @$scss_src : $scss_src
    );
};

has compile_to => sub ($self) {
    my $compile_to = join( '/',
        $self->conf->get( qw( config_app root_dir ) ),
        $self->conf->get( qw( sass compile_to ) ),
    );

    path($compile_to)->dirname->make_path;

    return $compile_to;
};

has report_cb => \ sub {};
has error_cb  => \ sub ($error) { die $error . "\n" };

sub build (
    $self,
    $report_cb = $self->report_cb,
    $error_cb  = $self->error_cb,
) {
    unless ( $self->scss_src ) {
        $error_cb->('scss_src is empty');
        return;
    }

    my ( $output, $error );
    try {
        run3(
            [
                'sass',
                '--stdin',
                '--no-source-map',
                '--no-error-css',
                '--color',
                '--style=' . ( ( $self->mode ne 'production' ) ? 'expanded' : 'compressed' ),
            ],
            \$self->scss_src,
            \$output,
            \$error,
        );

        unless ($error) {
            path( $self->compile_to )->spurt($output);
            $report_cb->();
        }
    }
    catch {
        s/\s*at .+? line \d+\.\s*//;
        $error_cb->($_);
    };

    $error_cb->($error) if $error;

    return;
};

1;

=head1 NAME

Omniframe::Util::Sass

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::Sass;

    my $sass = Omniframe::Util::Sass->new;

    say $sass->mode;
    say $sass->scss_src;
    say $sass->compile_to;

    $sass->report_cb( sub { return sub {} } );
    $sass->error_cb(  sub { return sub ($error) { die $error . "\n" } } );

    $sass->build;
    $sass->build(
        sub {},
        sub ($error) { die $error . "\n" },
    );

=head1 DESCRIPTION

This class will build CSS output based on SASS input using C<sass>. This module
assumes this is provided by the Dart-Sass command-line tool, installed prior to
use.

=head1 ATTRIBUTES

=head2 mode

This is the current "mode" of the application enviornment. This is synonymous
with the L<Mojolicious> mode. If not set explicitly, C<mode> will be set based
on the C<MOJO_MODE> enviornment variable, then the C<PLACK_ENV> enviornment
variable, then just defaulted to "development".

This attribute is used to determine if the CSS output is human-readble with
comments or tightly formed for production purposes.

=head2 scss_src

This represents the source SASS input. Typically this will be a series of
imports:

    @import '/path/to/file.cscc';
    @import '/path/to/other_file.cscc';

If not defined, it's created based on the applications configuration. See
L</"CONFIGURATION"> below.

=head2 compile_to

This represents the target location for CSS output.

=head2 report_cb

This is a reference to a sub that's called on success of any C<build> call. By
default, the following is created if nothing else is specified:

    $sass->report_cb(
        sub {}
    );

=head2 error_cb

This is a reference to a sub that's called on any errors and to which errors are
passed. By default, the following is created if nothing else is specified:

    $sass->error_cb(
        sub ($error) {
            die $error;
        }
    );

=head1 METHODS

=head2 build

This method will execute the build of the CSS from SASS. If there are any
errors, the error callback will be called and passed the error text. On success,
the report callback will be called. You can optionally override the callbacks
on specific calls to C<build>:

    $sass->build(
        sub {},
        sub ($error) { die $error . "\n" } },
    );

=head1 CONFIGURATION

The following is the default configuration, which can be overridden in the
application's configuration file. See L<Omniframe::Role::Conf>.

    sass:
        scss_src: config/assets/sass/app.scss
        compile_to: static/app.css

Configuration is pulled from the application's configuration and stored in the
object on first call to C<build> or on first call to any of the attributes.

Note that C<scss_src> can be either a scalar string or an arrayref of scalar
strings. Each will be assumed to be the relative location of a file to import.

=head1 WITH ROLES

L<Omniframe::Role::Conf>.

=head1 INHERITANCE

L<Omniframe>.
