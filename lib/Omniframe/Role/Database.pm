package Omniframe::Role::Database;

use exact -role;
use App::Dest;
use Cwd 'cwd';
use DBIx::Query;
use Mojo::File 'path';
use YAML::XS;

with qw( Omniframe::Role::Conf Omniframe::Role::Time );

my $globals = {
    default_shard => undef,
    dq_shards     => undef,
    dq_logs       => {},
};

sub _global_accessor ( $key, $value ) {
    $globals->{$key} = ( ref $value eq 'SCALAR' and not defined $$value ) ? undef : $value if ($value);
    return $globals->{$key};
}

sub default_shard ( $self, $data = undef ) { _global_accessor( 'default_shard', $data ) }
sub dq_shards     ( $self, $data = undef ) { _global_accessor( 'dq_shards',     $data ) }
sub dq_logs       ( $self, $data = undef ) { _global_accessor( 'dq_logs',       $data ) }

sub dq ( $self, $shard = undef ) {
    my $return_shard = sub {
        $shard //= $self->default_shard;
        croak('Database shard not specified and default shard not set') if ( not defined $shard );
        croak('Database shard requested not defined') unless ( $self->dq_shards->{$shard} );
        return $self->dq_shards->{$shard};
    };
    return $return_shard->() if ( ref $self->dq_shards eq 'HASH' );

    my $conf_full = $self->conf->get('database');
    my $root_dir  = $self->conf->get( qw( config_app root_dir ) );

    my @shards;
    if ( $conf_full->{shards} ) {
        @shards = map {
            $self->default_shard($_) if ( $conf_full->{shards}{$_}{default_shard} );

            my $shard_conf = YAML::XS::Load( YAML::XS::Dump( {
                %$conf_full,
                %{ $conf_full->{shards}{$_} },
                shard => $_,
            } ) );

            delete $shard_conf->{shards};

            $shard_conf;
        } keys %{ $conf_full->{shards} };
    }
    else {
        $self->default_shard('default_shard');
        @shards = { %$conf_full, shard => 'default_shard' };
    }

    $_->{path} = $root_dir . '/' . $_->{file} for (@shards);

    if ( my @to_be_created_db_files = grep { not -f $_ } map { $_->{path} } @shards ) {
        path($_)->dirname->make_path for (@to_be_created_db_files);

        my $cwd = cwd;
        chdir $root_dir;

        try {
            App::Dest->init;
            App::Dest->update;
        }
        catch ($e) {}

        chdir $cwd;
    }

    $self->dq_shards({
        map {
            my $conf = $_;

            my $dq = DBIx::Query->connect(
                'dbi:SQLite:dbname=' . $conf->{path},
                undef,
                undef,
                $conf->{settings},
            );

            $dq->do("PRAGMA $_->[0] = $_->[1]")
                for ( map { [ $_, $dq->quote( $conf->{pragmas}{$_} ) ] } keys %{ $conf->{pragmas} } );

            if ( $conf->{log} ) {
                $self->dq_logs->{ $conf->{shard} } = { map {
                    my $log_file = $root_dir . '/' . $conf->{log}{$_};
                    open( my $fh, '>>', $log_file )
                        or croak( 'failed to open SQL log file for appending: ' . $log_file );
                    $fh->autoflush(1);
                    $_ => $fh;
                } keys %{ $conf->{log} } };

                $dq->sqlite_trace( sub ($sql) {
                    my $time = ($self) ? $self->time->set->format('sqlite') : time;

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

                    my $log_fhs = $self->dq_logs->{ $conf->{shard} };
                    if (
                        $log_fhs->{all} or
                        ( $log_fhs->{write} and $write ) or
                        ( $log_fhs->{read} and not $write )
                    ) {
                        my $this_sql = $sql;
                        $this_sql =~ s/(\s*)$/;$1/ms unless ( $this_sql =~ /;\s*$/ms );
                        my $message = '-- ' . $time . "\n" . $this_sql . "\n\n";

                        print { $log_fhs->{all}   } $message if ( $log_fhs->{all}                  );
                        print { $log_fhs->{write} } $message if ( $log_fhs->{write} and $write     );
                        print { $log_fhs->{read}  } $message if ( $log_fhs->{read}  and not $write );
                    }

                    return 1;
                } );
            }

            $conf->{shard} => $dq;
        } @shards
    });

    return $return_shard->();
}

1;

=head1 NAME

Omniframe::Role::Database

=head1 SYNOPSIS

    package Package;

    use exact -class;

    with 'Omniframe::Role::Database';

    sub method ($self) {
        return $self->dq
            ->sql('SELECT name FROM thing WHERE thing_id = ?')->run(42)->value;
    }

    sub method_via_aux_db ($self) {
        return $self->dq('aux_db')
            ->sql('SELECT name FROM thing WHERE thing_id = ?')->run(42)->value;
    }

=head1 DESCRIPTION

This role provides a single C<dq> method which returns an application-wide
singleton L<DBIx::Query> object or objects connected to the application's
SQLite database(s).

=head1 METHODS

=head2 dq

This method will return an application-wide singleton L<DBIx::Query> object or
objects connected to the application's SQLite database(s).

    $self->dq;             # return the default shard database singleton
    $self->dq('specific'); # return the "specific" shard database singleton

When first accessed, a series of actions will take place that will create and
save the singleton(s). On subsequent accesses, the singleton(s) is/are returned.

First, database configuration is established. See L</"CONFIGURATION"> below.

Next, the directory for the database is created if it doesn't already exist.

Then the L<App::Dest> C<init> and C<update> methods are called. This assumes
there is a C<dest.watch> file in the project's root directory. If not, then
nothing happens.

Finally, using the L<DBIx::Query> C<connect> method, the database object is
instantiated, and then specific SQLite pragmas are set.

=head1 GLOBAL ATTRIBUTES

=head2 default_shard

This attribute represents the default "shard" (which SQLite database) to return
the singleton of if not specified in the C<dq> call.

If not set explicitly and there's only a single database without a shard name,
the C<default_shard> value will be set to "default_shard", which will be the
name automatically given to the single database.

=head2 dq_shards

This contains a hashref with keys of the names of each database "shard" and the
values being the associated L<DBIx::Query> object.

=head2 dq_logs

This contains a hashref with possible keys of "read", "write", and/or "all".
The values of any keys will be filehandles to the read, write, or all SQL log
files.

The values are generated automatically based on the configuration. See
L</"CONFIGURATION"> below.

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

If you replace C<file> with C<shards>, each key of that hashref will be
considered the name of the "shard" and the value will be a hashref of settings
specific to that "shard".

In a multi-shard setup, you can specify a positive value for C<default_shard>
to indicate which shard is the default.

    database:
        shards:
            user:
                default_shard: 1
                file: local/user.sqlite
                log:
                    all: local/user_log.sql
            lookup:
                file: local/lookup.sqlite
        settings:
            sqlite_see_if_its_a_number: 1
            sqlite_defensive: 1
            RaiseError: 1
            PrintError: 0
        pragmas:
            encoding: UTF-8
            foreign_keys: ON
            recursive_triggers: ON
            temp_store: MEMORY

=head1 WITH ROLES

L<Omniframe::Role::Conf>, L<Omniframe::Role::Time>.
