package Omniframe::Mojo::Socket;

use exact 'Omniframe';
use Mojo::File 'path';
use Mojo::JSON qw( decode_json encode_json );
use Mojo::Util 'trim';
use Proc::ProcessTable;

with qw( Omniframe::Role::Conf Omniframe::Role::Database Omniframe::Role::Logging );

class_has sockets => {};
class_has ppid    => undef;

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
    $self->ppid( getppid() );

    $SIG{URG} = sub {
        for my $socket ( @{ $self->dq->sql('SELECT name, counter FROM socket')->run->all({}) } ) {
            if (
                exists $self->sockets->{ $socket->{name} } and
                defined $self->sockets->{ $socket->{name} }{counter} and defined $socket->{counter} and
                $self->sockets->{ $socket->{name} }{counter} < $socket->{counter}
            ) {
                $self->sockets->{ $socket->{name} }{counter} = $socket->{counter};
                $self->debug( 'Socket messaged; ' . $$ . ' responding: ' . $socket->{name} );

                $_->send({
                    json => decode_json(
                        $self->dq->sql('SELECT data FROM socket WHERE name = ?')
                            ->run( $socket->{name} )->value
                    ),
                }) for ( values %{ $self->sockets->{ $socket->{name} }{transactions} } );
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

            Mojo::IOLoop->stream( $c->tx->connection )->timeout(
                $self->conf->get( qw( mojolicious ws_inactivity_timeout ) )
            );

            $c->on( finish => sub { $c->socket( finish => $socket_name ) } );

            $self->dq->sql(q{
                INSERT INTO socket (name) VALUES (?) ON CONFLICT(name) DO NOTHING
            })->run($socket_name);

            $self->sockets->{$socket_name}{counter} = $self->dq->sql(q{
                SELECT counter FROM socket WHERE name = ?
            })->run($socket_name)->value;

            $self->sockets->{$socket_name}{transactions}{ sprintf( '%s', $c->tx ) } = $c->tx;
            $self->info("Socket setup: $socket_name");
        }
        elsif ( $command eq 'message' ) {
            $self->message( $socket_name, $data );
        }
        elsif ( $command eq 'finish' ) {
            delete $self->sockets->{$socket_name}{transactions}{ sprintf( '%s', $c->tx ) };
            if ( not keys $self->sockets->{$socket_name}{transactions}->%* ) {
                delete $self->sockets->{$socket_name};
                $self->dq->sql('DELETE FROM socket WHERE name = ?')->run($socket_name);
            }
            $self->info("Socket finished: $socket_name");
        }

        return $c;
    };
}

sub message ( $self, $socket_name, $data ) {
    if ( $self->dq->sql('SELECT COUNT(*) FROM socket WHERE name = ?')->run($socket_name)->value ) {
        $self->dq->sql(q{
            UPDATE socket SET counter = counter + 1, data = ? WHERE name = ?
        })->run( encode_json($data), $socket_name );

        my $table = Proc::ProcessTable->new( enable_ttys => 0 )->table;
        my $ppid  = $self->ppid;

        unless ($ppid) {
            my $pid_file = path(
                $self->conf->get( qw( config_app root_dir ) ) . '/' .
                $self->conf->get( qw( mojolicious config hypnotoad pid_file ) )
            );
            $ppid = trim( $pid_file->slurp ) if ( -r $pid_file );

            unless ($ppid) {
                my @pses  = grep { $_->uid == $< } @$table;
                my @ppses =
                    grep {
                        defined;
                    }
                    map {
                        my $this_ppid = $_->ppid;
                        my ($parent_ps)   = grep { $_->pid  eq $this_ppid } @pses;
                        my @children_pses = grep { $_->ppid eq $this_ppid } @pses;
                        (
                            $parent_ps and
                            $parent_ps->cmndline eq $_->cmndline and
                            $parent_ps->fname =~ /\.(psgi|pl|cgi)$/i and
                            @children_pses == 1
                        ) ? $parent_ps : undef;
                    } @pses;

                $ppid = $ppses[0]->pid if ( @ppses == 1 );
            }

            $self->ppid($ppid) if ($ppid);
        }

        kill( 'URG', $_ ) for ( map { $_->pid } grep { $_->ppid == $ppid } $table->@* );
    }
    return $self;
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

=head2 message

This method performs the work of processing a message (i.e. saving to the
database and sending a signal to application children to read and send the data
over open sockets). The method is available/exposed so that it can if desired
be called from outside the Mojolicious application.

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
