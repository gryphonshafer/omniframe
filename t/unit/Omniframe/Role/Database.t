use Test2::V0;
use exact -conf;
use Omniframe;

my $obj;
ok( lives { $obj = Omniframe->with_roles('+Database')->new }, q{with_roles('+Database')->new} ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Database' );
can_ok( $obj, qw{ dq dq_setup } );
is( ref $obj->dq, 'DBIx::Query::db', 'dq() is a DBIx::Query' );

my $sqlite_master_count;
ok(
    lives { $sqlite_master_count = $obj->dq->sql('SELECT COUNT(*) FROM sqlite_master')->run->value },
    'database objects query',
) or note $@;
ok( $sqlite_master_count > -1, 'database exists' );

done_testing;
