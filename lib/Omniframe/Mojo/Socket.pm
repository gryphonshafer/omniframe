package Omniframe::Mojo::Socket;

use exact 'Omniframe';
use Mojo::JSON qw( decode_json encode_json );

with qw( Omniframe::Role::Conf Omniframe::Role::Database Omniframe::Role::Logging );

class_has sockets => {};

my $table_sql = q{CREATE TABLE IF NOT EXISTS socket (
    socket_id     INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL CHECK( LENGTH(name) > 0 ) UNIQUE,
    counter       INTEGER NOT NULL DEFAULT 0,
    data          TEXT,
    last_modified TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) ),
    created       TEXT    NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) )
);};

my $trigger_sql = q{CREATE TRIGGER IF NOT EXISTS socket_after_update AFTER UPDATE OF
    name,
    counter,
    data
ON socket
BEGIN
    UPDATE socket SET last_modified = STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' )
    WHERE socket_id = old.socket_id;
END;};

sub setup ($self) {
    $self->dq->sql($_)->run for ( $table_sql, $trigger_sql );

    $SIG{URG} = sub {
        for my $socket ( @{ $self->dq->sql('SELECT name, counter, data FROM socket')->run->all({}) } ) {
            if (
                $self->sockets->{ $socket->{name} } and
                $self->sockets->{ $socket->{name} }{counter} and $socket->{counter} and
                $self->sockets->{ $socket->{name} }{counter} < $socket->{counter}
            ) {
                $self->sockets->{ $socket->{name} }{counter} = $socket->{counter};
                $self->debug( 'Socket ' . $socket->{name} . ' was messaged; ' . $$ . ' responding' );

                for ( values %{ $self->sockets->{ $socket->{name} }{transactions} } ) {
                    try { $socket->{data} = decode_json( $socket->{data} ) } catch ($e) {}
                    $_->send({ json => $socket->{data} });
                }
            }
        }
    };

    return $self;
}

sub event_handler ($self) {
    return sub ( $c, $command, $socket_name, $data = undef ) {
        confess(qq{Socket event handler command "$command" not understood})
            if ( not grep { $command eq $_ } qw( setup message finish ) );

        if ( $command eq 'setup' ) {
            return $c->redirect_to('/') unless ( $c->tx->is_websocket );
            $c->inactivity_timeout( $self->conf->get( qw( mojolicious ws_inactivity_timeout ) ) );
            $c->on( finish => sub { $c->socket( finish => $socket_name ) } );

            $self->dq->sql('INSERT OR REPLACE INTO socket (name) VALUES (?)')->run($socket_name);
            $self->sockets->{$socket_name}{counter} = $self->dq->sql(q{
                SELECT counter FROM socket WHERE name = ?
            })->run($socket_name)->value;

            $self->sockets->{$socket_name}{transactions}{ sprintf( '%s', $c->tx ) } = $c->tx;
            $self->info("Socket $socket_name setup");
        }
        elsif ( $command eq 'message' ) {
            $self->dq->sql(q{
                UPDATE socket SET counter = counter + 1, data = ? WHERE name = ?
            })->run(
                ( ( ref $data ) ? encode_json($data) : $data ),
                $socket_name,
            );

            my $ppid = getppid();
            kill( 'URG', $_ ) for (
                map { $_->[0] }
                grep { $_->[1] == $ppid }
                map {
                    /(\d+)\D+(\d+)/;
                    [ $1, $2 ];
                }
                grep { index( $_, $ppid ) != -1 }
                `/bin/ps xa -o pid,ppid`
            );
        }
        elsif ( $command eq 'finish' ) {
            delete $self->sockets->{$socket_name}{transactions}{ sprintf( '%s', $c->tx ) };
            $self->info("Socket $socket_name finished");
        }

        return $c;
    };
}

1;

=head1 NAME

Omniframe::Mojo::Socket

=head1 SYNOPSIS

    package Project::Control;

    use exact 'Omniframe::Control';
    use Omniframe::Mojo::Socket;

    sub startup ($self) {
        $self->helper(
            socket => Omniframe::Mojo::Socket->new->setup->event_handler
        );

        my $r = $self->routes;

        $r->websocket( '/ws' => sub ($c) {
            $c->socket( setup => 'example_ws' );
        } );

        $r->any( '/*null' => { null => undef } => sub ($c) {
            $c->socket( message => 'example_ws', { time => time() } );
            $c->render( template => 'example/index' );
        } );

        return;
    }

=head1 DESCRIPTION

This package provides methods to enable setup of a simple sockets mechanism
in Mojolicious applications. First, you need to call C<setup> to setup the
database for socket data transfer and to establish a URG signal handler
receiver, which will be used to catch thrown triggers for outbound messages.
Second, you need to call C<event_handler> to return a subroutine reference that
can be used in a Mojolicious helper.

    $self->helper(
        socket => Omniframe::Mojo::Socket->new->setup->event_handler
    );

=head1 CLASS ATTRIBUTES

=head2 sockets

This class-level attribute is a storage mechanism for active websocket
listeners. Typically, you don't need to access or alter this data directly.

=head1 METHODS

=head2 setup

This method sets up the database table called C<socket> and trigger called
C<socket_before_update> for socket data transfer, and it establishs a URG signal
handler receiver, which will be used to catch thrown triggers for outbound
messages. This method accepts no input parameters.

=head2 event_handler

This method will return a subroutine reference that can be used in a
Mojolicious helper.

    $self->helper(
        socket => Omniframe::Mojo::Socket->new->setup->event_handler
    );

This helper once set can be called with socket action, socket name, and optional
data payload in the case of message send. The socket actions supported are:
setup, message, and finish.

The "setup" action establishes a socket with a given name:

    $c->socket( setup => 'example_ws' );

Part of the socket setup process includes setting C<inactivity_timeout> using
the C<mojolicious>, C<ws_inactivity_timeout> configuration keys. See
L</"CONFIGURATION"> below.

The "message" action sends a message over the named socket. The message is a
data payload provided as the third argument:

    $c->socket( message => 'example_ws', { time => time() } );

The "message" action is called automatically for you.

=head1 CONFIGURATION

The following is the default configuration, which can be overridden in the
application's configuration file. See L<Omniframe::Role::Conf>.

    mojolicious:
        ws_inactivity_timeout: 14400 # 4 hours

=head1 WITH ROLES

L<Omniframe::Role::Conf>, L<Omniframe::Role::Database>,
L<Omniframe::Role::Logging>.

=head1 INHERITANCE

L<Omniframe>.
