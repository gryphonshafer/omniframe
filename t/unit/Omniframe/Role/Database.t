use Test::Most;
use exact -conf;

my $obj;
use_ok('Omniframe');
lives_ok( sub { $obj = Omniframe->new->with_roles('+Database') }, q{new->with_roles('+Database')} );
ok( $obj->does("Omniframe::Role::$_"), "does $_ role" ) for ( qw( Conf Database ) );
can_ok( $obj, 'dq' );
is( ref $obj->dq, 'DBIx::Query::db', 'dq() is a DBIx::Query' );

my $sqlite_master_count;
lives_ok(
    sub { $sqlite_master_count = $obj->dq->sql('SELECT COUNT(*) FROM sqlite_master')->run->value },
    'database objects query',
);
ok( $sqlite_master_count > -1, 'database exists' );

done_testing();
