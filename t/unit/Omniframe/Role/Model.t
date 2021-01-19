use Test2::V0;
use DBIx::Query;
use Omniframe;

my $mock = mock 'DBIx::Query' => (
    set => {
        add  => 42,
        data => sub { { model_id => 42, thx => 1138 } },
        all  => sub { [ { model_id => 42, thx => 1138 }, { model_id => 43, thx => 1139 } ] },
        map { $_ => sub { $_[0] } } qw( _connect do get where run next update rm ),
    },
);

my $obj;
ok( lives { $obj = Omniframe->new->with_roles('+Model') }, q{new->with_roles('+Model')} ) or note $@;
DOES_ok( $obj, "Omniframe::Role::$_" ) for ( qw( Conf Database Logging Model ) );
can_ok( $obj, $_ ) for ( qw(
    name id_name id data create load save delete every every_data data_merge resolve_id
) );

like( dies { $obj->create(undef) }, qr/create\(\) data hashref contains no data/, 'create() sans data' );
like( dies { $obj->load(undef) }, qr/load\(\) called without input/, 'load() sans data' );
like(
    dies { $obj->delete },
    qr/Cannot delete\(\) an object without loaded data/,
    'delete() sans data',
);

ok( lives { $obj->create({ thx => 1138 }) }, 'create()' ) or note $@;
is( $obj->id, 42, 'id()' );
is( $obj->data, { model_id => 42, thx => 1138 }, 'data()' );

ok( lives { $obj = $obj->new({ alpha => 'beta' }) }, 'new($data)' ) or note $@;
ok( lives { $obj->create({ thx => 1138 }) }, 'create() with merged data' ) or note $@;

$obj->id(undef);
ok( lives { $obj->save({ thx => 1138 }) }, 'save() with merged data sans id' ) or note $@;
ok( lives { $obj->save({ thx => 1138 }) }, 'save() with merged data with id' ) or note $@;

ok( lives { $obj->delete }, 'delete()' ) or note $@;
ok( lives { $obj->delete( 1, 2, 3 ) }, 'delete( 1, 2, 3 )' ) or note $@;

my $rv;
ok( lives { $rv = $obj->every({}) }, 'every()' ) or note $@;
is( $rv, [
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

ok( lives { $rv = $obj->every_data({}) }, 'every_data()' ) or note $@;
is( $rv, [ { model_id => 42, thx => 1138 }, { model_id => 43, thx => 1139 } ], 'every_data() data check' );

is( $obj->resolve_id(1138), 1138, 'resolve_id(id)' );
is( $obj->resolve_id($obj), 42, 'resolve_id(obj)' );

done_testing;
