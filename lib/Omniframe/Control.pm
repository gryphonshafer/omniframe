package Omniframe::Control;

use exact 'Omniframe', 'Mojolicious';
use HTML::Packer;
use JavaScript::Packer;
use Mojo::File 'path';
use Mojo::Loader qw( find_modules load_class );
use MojoX::Log::Dispatch::Simple;
use Omniframe::Class::Sass;
use Omniframe::Class::Time;

with qw( Omniframe::Role::Conf Omniframe::Role::Logging Omniframe::Role::Template );

my $time = Omniframe::Class::Time->new;

has sass => sub { Omniframe::Class::Sass->new };

sub startup ($self) {
    $self->setup;

    my $r = $self->routes;

    $r->websocket( '/ws' => sub ($c) {
        $c->socket( setup => 'example_ws' );
    } );

    $r->any( '/test.js' => sub ($c) {
        return $c->document('/static/js/util/browser_test.js');
    } );

    $r->any( '/api' => sub ($c) {
        $c->render( json => { request => $c->req->json } );
    } );

    $r->any( '/*null' => { null => undef } => sub ($c) {
        $c->socket( message => 'example_ws', { time => time() } );
        $c->stash(
            package => __PACKAGE__,
            now     => scalar(localtime),
            copy    => "\xa9",
            input   => $c->param('input'),
        );
        $c->render( template => 'example/index' );
    } );
}

sub setup ( $self, %params ) {
    my $run = { map { $_ => 1 } ( ref $params{run} eq 'ARRAY' ) ? $params{run}->@* : qw(
        mojo_logging
        request_base
        sass_build
        access_log
        templating
        static_paths
        config
        packer
        compressor
        sockets
        document
        devdocs
        preload_controllers
    ) };
    delete $run->{$_} for ( @{ $params{skip} // [] } );

    $self->setup_mojo_logging if $run->{mojo_logging};

    $self->plugin('RequestBase') if $run->{request_base};
    $self->sass->build           if $run->{sass_build};

    $self->setup_access_log   if $run->{access_log};
    $self->setup_templating   if $run->{templating};
    $self->setup_static_paths if $run->{static_paths};
    $self->setup_config       if $run->{config};
    $self->setup_packer       if $run->{packer};
    $self->setup_compressor   if $run->{compressor};
    $self->setup_sockets      if $run->{sockets};
    $self->setup_document     if $run->{document};
    $self->setup_devdocs      if $run->{devdocs};

    $self->preload_controllers if $run->{preload_controllers};
    return;
}

sub setup_mojo_logging ($self) {
    $self->log(
        MojoX::Log::Dispatch::Simple->new(
            dispatch  => $self->log_dispatch,
            level     => $self->log_level,
            format_cb => sub ( $timestamp, $level, @messages ) { join( '',
                $time->datetime( 'log', $timestamp ),
                ' [' . uc($level) . '] ',
                join( "\n", $self->dp( [ @messages, '' ], colored => 0 ) ),
            ) },
        )
    );

    for my $level ( @{ $self->log_levels } ) {
        $self->helper( $level => sub ( $c, @messages ) {
            $self->log->$level($_) for ( $self->dp(\@messages) );
            return;
        } );
    }

    $self->info('Setup mojo logging');
    return;
}

sub setup_access_log ($self) {
    my $access_log = join( '/',
        $self->conf->get( qw( config_app root_dir ) ),
        $self->conf->get( qw( mojolicious access_log ) ),
    );

    path($access_log)->dirname->make_path;

    my $log_level = $self->log->level;
    $self->log->level('error'); # temporarily raise log level to skip AccessLog "warn" status
    $self->plugin( 'AccessLog', { log => $access_log } );
    $self->log->level($log_level);

    $self->info('Setup access log');
    return;
}

sub setup_templating ($self) {
    push( @INC, $self->conf->get( 'config_app', 'root_dir' ) );
    $self->plugin( 'ToolkitRenderer', $self->tt_settings );
    $self->renderer->default_handler('tt');

    $self->info('Setup templating');
    return;
}

sub setup_static_paths ($self) {
    my $root_dir = $self->conf->get( qw( config_app root_dir ) );
    my $paths    = [ map {
        join( '/', $root_dir, $_ )
    } @{ $self->conf->get( qw( mojolicious static_paths ) ) } ];

    if ( my $omniframe = $self->conf->get('omniframe') ) {
        push(
            @$paths,
            map {
                join( '/', $root_dir, $omniframe, $_ )
            } @{ $self->conf->get( qw( mojolicious static_paths ) ) }
        );
    }

    $self->static->paths($paths);

    $self->info('Setup static paths');
    return;
}

sub setup_config ($self) {
    my $config = $self->conf->get( 'mojolicious', 'config' );

    path( $config->{hypnotoad}{pid_file} )->dirname->make_path;

    $self->config($config);

    my $secrets = $self->conf->get( 'mojolicious', 'secrets' );
    $self->secrets($secrets) if ($secrets);

    $self->sessions->cookie_name( $self->conf->get( qw( mojolicious session cookie_name ) ) );
    $self->sessions->default_expiration( $self->conf->get( qw( mojolicious session default_expiration ) ) );

    $self->info('Setup config');
    return;
}

sub setup_packer ( $self, $opts = {} ) {
    my $packer = HTML::Packer->init;

    $self->hook( after_render => sub ( $c, $output, $format ) {
        $packer->minify( $output, $opts ) if ( $format eq 'html' );
        return;
    } );

    $self->info('Setup packer');
    return;
}

sub setup_compressor ($self) {
    $self->renderer->compress(1) unless ( $self->mode eq 'development' );
    $self->info('Setup compressor');
    return;
}

sub setup_sockets ($self) {
    require Omniframe::Mojo::Socket;
    $self->helper( socket => Omniframe::Mojo::Socket->new->setup->event_handler );
    $self->info('Setup socket system');
    return;
}

sub setup_document ($self) {
    require Omniframe::Mojo::Document;
    my $document = Omniframe::Mojo::Document->new;
    $self->helper( document => $document->document_helper );
    $self->helper( docs_nav => $document->docs_nav_helper );
    $self->info('Setup document system');
    return;
}

sub setup_devdocs (
    $self,
    $location = '/devdocs',
    $trigger = sub ($app) {
        $app->mode eq 'development'
    },
) {
    return unless ( $trigger->($self) );
    require Omniframe::Mojo::DevDocs;
    Omniframe::Mojo::DevDocs->new->setup( $self, $location );
    $self->info('Setup development documents');
    return;
}

sub preload_controllers ($self) {
    for ( map { find_modules($_) } 'Omniframe::Control', ref($self) ) {
        if ( my $error = load_class($_) ) {
            $self->error("Error loading: $_ -- $error");
        }
        else {
            $self->info("Preload controller $_");
        }
    }

    return;
}

1;

=head1 NAME

Omniframe::Control

=head1 SYNOPSIS

=for test_synopsis BEGIN { $SIG{__WARN__} = sub {} }

    package Project::Control;

    use exact 'Omniframe::Control';

    sub startup ($self) {
        # $self->setup; ## <-- this does all of the following code block:

        $self->setup_mojo_logging;
        $self->plugin('RequestBase');
        $self->sass->build;
        $self->setup_access_log;
        $self->setup_templating;
        $self->setup_static_paths;
        $self->setup_config;
        $self->setup_packer;
        $self->setup_compressor;
        $self->setup_sockets;
        $self->setup_document;
        $self->setup_devdocs;
        $self->preload_controllers;

        $self->routes->any( '/*null' => { null => undef } => sub ($c) {
            $c->render( text => __PACKAGE__ . '::startup() -- ' . scalar(localtime) );
        } );

        return;
    }

=head1 DESCRIPTION

This class is a base class for application project controller base classes. It's
it not meant to be used directly as-is, although it can be. As the super-class,
it provides to the application project controller a series of methods for
web application enviornment setup.

=head1 ATTRIBUTES

=head2 sass

This attribute will on first access be set with an instantiated object of
L<Omniframe::Class::Sass>. The following 2 lines are equivalent:

        Omniframe::Class::Sass->new->build;
        $self->sass->build;

=head1 METHODS

=head2 startup

This is a basic, thin startup method for L<Mojolicious>; however, the
expectation is that this method will be overwritten by the subclass, an
application's project controller. This superclass method calls C<setup> and
sets a universal route that renders a basic text message.

=head2 setup

This method is a simple wrapper around other setup methods.

    $self->setup;

The above line is equivalent to the following block:

    $self->setup_mojo_logging;
    $self->plugin('RequestBase');
    $self->sass->build;
    $self->setup_access_log;
    $self->setup_templating;
    $self->setup_static_paths;
    $self->setup_config;
    $self->setup_packer;
    $self->setup_compressor;
    $self->setup_sockets;
    $self->setup_document;
    $self->setup_devdocs;
    $self->preload_controllers;

The method optionally accepts input to explicitly specify the setup steps and/or
skip certain setup steps. For example, the following is equivalent to calling
C<$self->setup>:

    $self->setup( run => [ qw(
        mojo_logging
        request_base
        sass_build
        access_log
        templating
        static_paths
        config
        packer
        compressor
        sockets
        document
        devdocs
        preload_controllers
    ) ] );

The following will setup only the listed options:

    $self->setup( run => [ qw( mojo_logging templating config ) ] );

The following will setup all steps the lilsted options:

    $self->setup( skip => [ qw( document devdocs ) ] );

=head2 setup_access_log

This method establishes an access log via L<Mojolicious::Plugin::AccessLog>
using the C<mojolicious>, C<access_log> configuration key. See
L</"CONFIGURATION"> below.

=head2 setup_mojo_logging

This method connects L<Mojolicious> logging with the
L<Omniframe::Role::Logging> role via L<MojoX::Log::Dispatch::Simple>.

=head2 setup_templating

This method establishes L<Template> as the default viewer for the application
using L<Mojolicious::Plugin::ToolkitRenderer> and L<Omniframe::Role::Template>.

=head2 setup_static_paths

This method sets the static paths for the application. The static paths with be
C<~/static> both from the project application's root directory and the omniframe
root directory. The project's C<~/static> will come first, meaning files are
search for there first, then in the omniframe root directory next.

=head2 setup_config

This method sets the various configurations for a L<Mojolicious> application
using on the C<mojolicious>, C<config> and C<mojolicious>, C<session>
configuration keys. See L</"CONFIGURATION"> below.

=head2 setup_packer

This method sets up dynamic HTML content output packing via use of
L<HTML::Packer> and L<JavaScript::Packer>. The method will accept an optional
hashref containing options for L<HTML::Packer>.

=head2 setup_compressor

This method turns on Mojolicious GZip compression of dynamic output provided the
current mode is not development.

=head2 setup_sockets

This method will setup the C<sockets> Mojolicious helper via a lazy use of
L<Omniframe::Mojo::Socket> and a call to its C<setup> and C<event_handler>
methods.

=head2 setup_document

This method will setup the C<document> Mojolicious helper via a lazy use of
L<Omniframe::Mojo::Document> and a call to its C<helper> method.

=head2 setup_devdocs

This method will setup the "/devdocs" routes and functionality via a lazy use of
L<Omniframe::Mojo::DevDocs> and a call to its C<setup> method.

=head2 preload_controllers

This method will attempt to find all project controller subclasses and omniframe
controller subclasses and load them using L<Mojo::Loader>.

=head1 CONFIGURATION

The following is the default configuration, which can be overridden in the
application's configuration file. See L<Omniframe::Role::Conf>.

    mojolicious:
        access_log: local/access.log
        static_paths:
            - static
        config:
            hypnotoad:
                proxy: 1
                pid_file: local/hypnotoad.pid
                listen:
                    - http://*:8080
        session:
            cookie_name: omniframe_session
            default_expiration: 31557600 # 365.25 days

Note however that in the application's configuration file, secrets should be
found (although not directly if the YAML will be made public).

    mojolicious:
        secrets:
            - current_secret
            - old_secret

=head1 WITH ROLES

L<Omniframe::Role::Conf>, L<Omniframe::Role::Logging>,
L<Omniframe::Role::Template>.

=head1 INHERITANCE

L<Omniframe>, L<Mojolicious>.
