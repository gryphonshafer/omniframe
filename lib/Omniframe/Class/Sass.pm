package Omniframe::Class::Sass;

use exact 'Omniframe';
use IPC::Run3 'run3';
use Mojo::File 'path';

with 'Omniframe::Role::Conf';

has mode => sub ($self) {
    return $ENV{MOJO_MODE} || $ENV{PLACK_ENV} || 'development';
};

has scss_src => sub ($self) {
    my $omniframe = $self->conf->get('omniframe');
    my $root_dir  = $self->conf->get( qw( config_app root_dir ) );
    my $scss_src  = $self->conf->get( qw( sass scss_src ) );

    $scss_src = [$scss_src] unless ( ref $scss_src eq 'ARRAY' );

    return join( "\n",
        map { "\@use '$_';" }
        map {
            my $scss_file = join( '/', $root_dir, $_ );
            $scss_file = join( '/', $root_dir, $omniframe, $_ )
                if ( $omniframe and not $self->exists($scss_file) );

            croak( 'Unable to locate SCSS file: ' . $scss_file ) if ( not $self->exists($scss_file) );
            $scss_file;
        }
        @$scss_src
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

    my $scss_src = $self->conf->get( qw( sass scss_src ) );
    $scss_src = [$scss_src] unless ( ref $scss_src eq 'ARRAY' );

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
                (
                    map {
                        my $path = $_;
                        map {
                            '--load-path=' . path( $path . '/' . $_  )->realpath->dirname
                        }
                        grep {
                            path( $path . '/' . $_           )->stat or
                            path( $path . '/' . $_ . '.sass' )->stat or
                            path( $path . '/' . $_ . '.scss' )->stat or
                            path( $path . '/' . $_ . '.css'  )->stat
                        } @$scss_src;
                    }
                    grep { $_ }
                        $self->conf->get( qw( config_app root_dir ) ),
                        $self->conf->get('omniframe')
                ),
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
    catch ($e) {
        $e =~ s/\s*at .+? line \d+\.\s*//;
        $error_cb->($e);
    }

    $error_cb->($error) if $error;

    return;
}

sub exists ( $self, $scss ) {
    return
        grep { -r $_ }
        map {
            $scss . '.' . $_,
            '_' . $scss . '.' . $_,
            $scss . '/index.' . $_,
            $scss . '/_index.' . $_;
        } qw( css scss cass );
}

1;

=head1 NAME

Omniframe::Class::Sass

=head1 SYNOPSIS

    use exact;
    use Omniframe::Class::Sass;

    my $sass = Omniframe::Class::Sass->new;

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

    @use '/path/to/file';
    @use '/path/to/directory/with/index/file/in/it';

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

=head2 exists

Given a name, this method will check for a valid Sass reference (file or
directory with an index file inside) first within a project's scope and then
within Omniframe's scope.

    $sass->exists('name');

=head1 CONFIGURATION

The following is the default configuration, which can be overridden in the
application's configuration file. See L<Omniframe::Role::Conf>.

    sass:
        scss_src: config/assets/sass/app
        compile_to: static/app.css

Configuration is pulled from the application's configuration and stored in the
object on first call to C<build> or on first call to any of the attributes.

Note that C<scss_src> can be either a scalar string or an arrayref of scalar
strings. Each will be assumed to be the relative location of a file to import.

=head1 WITH ROLES

L<Omniframe::Role::Conf>.

=head1 INHERITANCE

L<Omniframe>.
