package Omniframe::Test::App;

use exact -conf;
use Test2::V0;
use Test2::MojoX;
use Omniframe;
use Omniframe::Control;

exact->export( qw{ setup stuff username email mojo url teardown } );

my $stuff = {};

sub setup {
    $ENV{MOJO_LOG_LEVEL} = 'error';

    my $obj = Omniframe->with_roles('+Database')->new;
    $obj->dq->begin_work;
    conf->put( qw( email active ) => 0 );

    my $mock_omniframe_control = mock 'Omniframe::Control' => (
        override => [ qw( setup_access_log debug info notice warning warn ) ],
    );

    $stuff->{$$} = {
        mojo  => Test2::MojoX->new( conf->get('mojo_app_lib') ),
        obj   => $obj,
        dq    => $obj->dq,
        mocks => {
            'Omniframe::Control' => $mock_omniframe_control,
        },
    };
}

sub username {
    ( my $username = lc( crypt( $$ . ( time + rand ), 'gs' ) ) ) =~ s/[^a-z0-9]+//g;
    state $count = 0;
    return $username . $count++;
}

sub email {
    return username . '@example.com';
}

sub stuff ($key) {
    return $stuff->{$$}{$key};
}

sub mojo {
    return stuff('mojo');
}

sub url (@url_parts) {
    return mojo->app->url_for(@url_parts)->to_string;
}

sub teardown {
    stuff('dq')->rollback;
    delete $stuff->{$$};
    done_testing;
}

1;

=head1 NAME

Omniframe::Test::App

=head1 SYNOPSIS

    use exact -conf;
    use Omniframe::Test::App;

    setup;

    my $dq       = stuff('dq');
    my $username = email;
    my $email    = email;

    mojo->get_ok('/')->status_is(200);

    teardown;

=head1 DESCRIPTION

This package provides functions to make Mojolicious application testing under
Omniframe a bit simpler and easier.

=head1 FUNCTIONS

=head2 setup

This function sets up the test enviornment. To reduce noise, it sets the
enviornment variable C<MOJO_LOG_LEVEL> to "error" and mocks silent methods from
L<Omniframe::Control> that would generate logging noise.

It begins a database transaction for the default database shard. It sets email
active to false. And if sets up some useful stuff for C<stuff>.

=head2 stuff

This function gives you access to "stuff" created during C<setup>.

    my $dq    = stuff('dq');    # DBIx::Query object of the default shard
    my $mocks = stuff('mocks'); # mocks setup by setup()
    my $obj   = stuff('obj');   # generic Omniframe object with Database role

=head2 username

Generates and returns a fake but useful username.

=head2 email

Generates and returns a fake but useful email address.

=head2 mojo

This function returns the L<Test2::MojoX> object for the application defined in
via the C<mojo_app_lib> configuration setting.

This function is an alias for:

    stuff('mojo');

=head2 url

This function requires a path or URL that will be processed via the
application's C<url_for> method and returned as a string.

=head2 teardown

This function rollsback the database transaction setup in C<setup>. It deletes
anything stored for C<stuff>. And it calles C<done_testing>.
