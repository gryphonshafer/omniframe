package Omniframe::Role::Database;

use exact -role;
use App::Dest;
use DBIx::Query;
use Mojo::File 'path';

with 'Omniframe::Role::Conf';

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
        };
    }

    my $dq = DBIx::Query->connect(
        'dbi:SQLite:dbname=' . $file,
        undef,
        undef,
        $conf->{settings},
    );

    $dq->do('PRAGMA foreign_keys = ON');
    $dq->do('PRAGMA encoding="UTF-8"');

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

=head1 WITH ROLES

L<Omniframe::Role::Conf>.
