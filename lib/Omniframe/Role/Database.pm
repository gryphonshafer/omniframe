package Omniframe::Role::Database;

use exact -role;
use App::Dest;
use DBD::SQLite;
use DBIx::Query;
use Mojo::File 'path';
use Omniframe::Util::Time;

with 'Omniframe::Role::Conf';

class_has time => sub { Omniframe::Util::Time->new },
class_has log  => sub ($self) {
    my $root_dir = $self->conf->get( qw( config_app root_dir ) );
    unless ( my $log = $self->conf->get( qw( database log ) ) ) {
        return;
    }
    else {
        return {
            map {
                open( my $fh, '>>', $root_dir . '/' . $log->{$_} )
                    or croak( 'failed to open SQL log file for appending: ' . $root_dir . '/' . $log->{$_} );
                $_ => $fh;
            } keys %$log
        };
    }
};

class_has dq => sub ($self) {
    my $conf     = $self->conf->get('database');
    my $root_dir = $self->conf->get( qw( config_app root_dir ) );
    my $file     = join( '/', $root_dir, $conf->{file} );

    path($file)->dirname->make_path;

    unless ( -f $file ) {
        chdir $root_dir;

        try {
            App::Dest->init;
            App::Dest->update;
        }
        catch {}
    }

    my $dq = DBIx::Query->connect(
        'dbi:SQLite:dbname=' . $file,
        undef,
        undef,
        $conf->{settings},
    );

    exact->monkey_patch(
        'DBIx::Query',
        quote => sub ( $self, @values ) {
            return DBD::SQLite::db->quote(@values);
        },
    );

    $dq->do("PRAGMA $_->[0] = $_->[1]")
        for ( map { [ $_, $dq->quote( $conf->{pragmas}{$_} ) ] } keys %{ $conf->{pragmas} } );

    if ( my $log = $self->log ) {
        $dq->sqlite_trace( sub ($sql) {
            my $write = (
                $sql =~ /^\s*(\w+)/ and not grep { lc($1) eq lc($_) } qw(
                    ANALYZE
                    EXPLAIN
                    PRAGMA
                    REINDEX
                    RELEASE
                    SAVEPOINT
                    SELECT
                    VACUUM
                )
            ) ? 1 : 0;

            if (
                $log->{all} or
                ( $log->{write} and $write ) or
                ( $log->{read} and not $write )
            ) {
                my $this_sql = $sql;
                $this_sql =~ s/(\s*)$/;$1/ms unless ( $this_sql =~ /;\s*$/ms );
                my $message = '-- ' . $self->time->zulu . "\n" . $this_sql . "\n\n";

                print { $log->{all}   } $message if ( $log->{all}                  );
                print { $log->{write} } $message if ( $log->{write} and $write     );
                print { $log->{read}  } $message if ( $log->{read}  and not $write );
            }

            return 1;
        } );
    }

    return $dq;
};

1;

=head1 NAME

Omniframe::Role::Database

=head1 SYNOPSIS

    package Package;

    use exact -class;

    with 'Omniframe::Role::Database';

    sub method ($self) {
        return $self->dq->sql('SELECT name FROM thing WHERE thing_id = ?')->run(42)->value;
    }

=head1 DESCRIPTION

This role provides a single C<dq> class attribute which is an application-wide
singleton L<DBIx::Query> object connected to the application's SQLite database.

=head1 CLASS ATTRIBUTES

=head2 dq

This class attribute, when accessed, will become an application-wide singleton
L<DBIx::Query> object connected to the application's SQLite database. When first
accessed, a series of actions will take place that will create and save the
singleton. On subsequent accesses, the singleton is returned.

First, database configuration is established. See L</"CONFIGURATION"> below.

Next, the directory for the database is created if it doesn't already exist.

Then the L<App::Dest> C<init> and C<update> methods are called. This assumes
there is a C<dest.watch> file in the project's root directory. If not, then
nothing happens.

Finally, using the L<DBIx::Query> C<connect> method, the database object is
instantiated, and then specific SQLite pragmas are set.

=head2 log

This contains a hashref with possible keys of "read", "write", and/or "all".
The values of any keys will be filehandles to the read, write, or all SQL log
files.

The values of C<log> are generated automatically based on the C<log>
configuration. See L</"CONFIGURATION"> below.

=head2 time

Contains an instantiated L<Omniframe::Util::Time> object used for logging the
time in SQL logs.

=head1 CONFIGURATION

The following is the default configuration, which can be overridden in the
application's configuration file. See L<Omniframe::Role::Conf>.

    database:
        file: local/app.sqlite
        settings:
            sqlite_see_if_its_a_number: 1
            sqlite_defensive: 1
            RaiseError: 1
            PrintError: 0
        pragmas:
            auto_vacuum: FULL
            encoding: UTF-8
            foreign_keys: ON
            temp_store: MEMORY
        log:
            write: local/db_write_log.sql
            read: local/db_read_log.sql
            all: local/db_log.sql

=head1 WITH ROLES

L<Omniframe::Role::Conf>.
