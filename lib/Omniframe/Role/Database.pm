package Omniframe::Role::Database;

use exact -role, -conf;
use App::Dest;
use Cwd 'cwd';
use DBIx::Query;
use File::Glob ':bsd_glob';
use Mojo::File 'path';
use Omniframe::Class::Time;
use Omniframe::Util::Data 'deepcopy';

my $root_dir  = conf->get( qw( config_app root_dir ) );
my $conf      = _dq_conf();

if ( my @to_be_created_db_files = grep { not -f $_ } map { $_->{file} } values %{ $conf->{shards} } ) {
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

my $pid       = $$;
my $omniframe = conf->get('omniframe');
my $time      = Omniframe::Class::Time->new;
my $shards    = _dq_shards();

sub _dq_conf {
    my $this_conf = deepcopy conf->get('database');

    unless ( $this_conf->{shards} ) {
        $this_conf = {
            default_shard => 'default_shard',
            shards        => { default_shard => $this_conf },
        };
    }
    else {
        my $shards_conf = delete $this_conf->{shards};
        for my $shard_name ( keys %$shards_conf ) {
            $shards_conf->{$shard_name}{file} //= $this_conf->{file} if ( $this_conf->{file} );
            for my $type ( qw( pragmas settings ) ) {
                if ( $this_conf->{$type} ) {
                    $shards_conf->{$shard_name}{$type}{$_} //= $this_conf->{$type}{$_}
                        for ( grep { $this_conf->{$type}{$_} } keys %{ $this_conf->{$type} } );
                }
            }
            $shards_conf->{$shard_name}{$_} //= $this_conf->{$_}
                for ( grep { $this_conf->{$_} } qw( log extensions ) );
        }
        $this_conf = { shards => $shards_conf };
        ( $this_conf->{default_shard} ) = grep { delete $shards_conf->{$_}{default_shard} } keys %$shards_conf;
        ( $this_conf->{default_shard} ) = sort keys %$shards_conf unless ( $this_conf->{default_shard} );
    }

    for my $shard ( values %{ $this_conf->{shards} } ) {
        $shard->{file} = $root_dir . '/' . $shard->{file};
        for my $log ( keys %{ $shard->{log} // {} } ) {
            $shard->{log}{$log} = $root_dir . '/' . $shard->{log}{$log};
        }
    }

    return $this_conf;
}

sub _dq_shards {
    $pid = $$;

    return { map {
        my $shard_name = $_;
        my $shard_conf = $conf->{shards}{$shard_name};

        my $dq = DBIx::Query->connect_uncached(
            'dbi:SQLite:dbname=' . $shard_conf->{file},
            undef,
            undef,
            $shard_conf->{settings},
        );

        if ( $shard_conf->{extensions} and @{ $shard_conf->{extensions} // [] } ) {
            $dq->sqlite_enable_load_extension(1);
            for my $extension ( @{ $shard_conf->{extensions} } ) {
                my ($library) = grep { -f $_ } map { bsd_glob( $_ . '.{so,dll}' ) } grep { defined } (
                    ($omniframe) ? $omniframe . '/' . $root_dir . '/' . $extension : undef,
                    $root_dir . '/' . $extension,
                    '/usr/lib/sqlite3/' . $extension,
                );

                try {
                    $dq->sqlite_load_extension( $library // '' );
                }
                catch ($e) {
                    die join( ' ',
                        'Failure of SQLite to load',
                        '"' . $extension . '"',
                        '--',
                        ( $library // '>>undef<<' ),
                        '--',
                        $e,
                    ) . "\n";
                }
            }
        }

        $dq->do("PRAGMA $_->[0] = $_->[1]")
            for ( map { [ $_, $dq->quote( $shard_conf->{pragmas}{$_} ) ] } keys %{ $shard_conf->{pragmas} } );

        if ( $shard_conf->{log} ) {
            my $dq_log_fhs = { map {
                open( my $fh, '>>', $shard_conf->{log}{$_} )
                    or croak( 'failed to open SQL log file for appending: ' . $shard_conf->{log}{$_} );
                $fh->autoflush(1);
                $_ => $fh;
            } keys %{ $shard_conf->{log} } };

            $dq->sqlite_profile( sub ( $sql, $elapsed_time ) {
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
                    $dq_log_fhs->{all} or
                    ( $dq_log_fhs->{write} and $write ) or
                    ( $dq_log_fhs->{read} and not $write )
                ) {
                    my $this_sql = $sql;
                    $this_sql =~ s/(\s*)$/;$1/ms unless ( $this_sql =~ /;\s*$/ms );

                    my $message =
                        '-- ' . $time->set->format('sqlite') . "\n" .
                        '-- ' . $elapsed_time . "\n" .
                        $this_sql . "\n\n";

                    print { $dq_log_fhs->{all}   } $message if ( $dq_log_fhs->{all}                  );
                    print { $dq_log_fhs->{write} } $message if ( $dq_log_fhs->{write} and $write     );
                    print { $dq_log_fhs->{read}  } $message if ( $dq_log_fhs->{read}  and not $write );
                }

                return 1;
            } );
        }

        $shard_name => $dq;
    } keys %{ $conf->{shards} } };
}

sub dq ( $self, $shard = undef ) {
    $shard //= $conf->{default_shard};
    $shards = _dq_shards() if ( not $shards or $pid != $$ );
    return $shards->{$shard};
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

=head1 CONFIGURATION

The following is the default configuration, which can be overridden in the
application's configuration file. See L<Config::App>.

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
