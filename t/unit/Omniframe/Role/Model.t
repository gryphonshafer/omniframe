use Test::Most;
use Test::MockModule;
use exact -conf;

my $dq = Test::MockModule->new('DBIx::Query');
$dq->mock( $_ => sub { $_[0] } ) for ( qw( _connect do get where run next update rm ) );
$dq->mock( 'add' => 42 );
$dq->mock( 'data' => { model_id => 42, thx => 1138 } );
$dq->mock( 'all' => [ { model_id => 42, thx => 1138 }, { model_id => 43, thx => 1139 } ] );

my $obj;
use_ok('Omniframe');
lives_ok( sub { $obj = Omniframe->new->with_roles('+Model') }, q{new->with_roles('+Model')} );
ok( $obj->does("Omniframe::Role::$_"), "does $_ role" ) for ( qw( Conf Database Logging Model ) );
can_ok( $obj, $_ ) for ( qw( name id_name id data create load save delete every every_data data_merge ) );

throws_ok( sub { $obj->create(undef) }, qr/create\(\) data hashref contains no data/, 'create() sans data' );
throws_ok( sub { $obj->load(undef) }, qr/load\(\) called without input/, 'load() sans data' );
throws_ok(
    sub { $obj->delete },
    qr/Cannot delete\(\) an object without loaded data/,
    'delete() sans data',
);

lives_ok( sub { $obj->create({ thx => 1138 }) }, 'create()' );
is( $obj->id, 42, 'id()' );
is_deeply( $obj->data, { model_id => 42, thx => 1138 }, 'data()' );

lives_ok( sub { $obj = $obj->new({ alpha => 'beta' }) }, 'new($data)' );
lives_ok( sub { $obj->create({ thx => 1138 }) }, 'create() with merged data' );

$obj->id(undef);
lives_ok( sub { $obj->save({ thx => 1138 }) }, 'save() with merged data sans id' );
lives_ok( sub { $obj->save({ thx => 1138 }) }, 'save() with merged data with id' );

lives_ok( sub { $obj->delete }, 'delete()' );
lives_ok( sub { $obj->delete( 1, 2, 3 ) }, 'delete( 1, 2, 3 )' );

my $rv;
lives_ok( sub { $rv = $obj->every({}) }, 'every()' );
is_deeply( $rv, [
    $obj->new(
        id => 42,
        data => { model_id => 42, thx => 1138 },
        _saved_data => { model_id => 42, thx => 1138 },
    ),
    $obj->new(
        id => 43,
        data => { model_id => 43, thx => 1139 },
        _saved_data => { model_id => 43, thx => 1139 },
    ),
], 'every() data check' );

lives_ok( sub { $rv = $obj->every_data({}) }, 'every_data()' );
is_deeply( $rv, [ { model_id => 42, thx => 1138 }, { model_id => 43, thx => 1139 } ], 'every_data() data check' );

done_testing();
