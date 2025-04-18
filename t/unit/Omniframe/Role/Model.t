use Test2::V0;
use DBD::SQLite;
use DBIx::Query;
use exact -conf;
use Omniframe;

my $mock = mock 'DBIx::Query' => (
    set => [
        add   => 42,
        data  => sub { { model_id => 42, thx => 1138 } },
        all   => sub { [ { model_id => 42, thx => 1138 }, { model_id => 43, thx => 1139 } ] },
        quote => sub { shift; DBD::SQLite::db->quote(@_) },
        map { $_ => sub { $_[0] } } qw(
            _connect do get where run next update rm sqlite_enable_load_extension sqlite_load_extension
        ),
    ],
);

my $obj;
ok( lives { $obj = Omniframe->with_roles('+Model')->new }, q{with_roles('+Model')->new} ) or note $@;
DOES_ok( $obj, "Omniframe::Role::$_" ) for ( qw( Database Logging Model ) );
can_ok( $obj, $_ ) for ( qw(
    name id_name active id data saved_data
    create load is_dirty dirty save delete every every_data data_merge resolve_id resolve_obj
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

my $rv;
ok( lives { $rv = $obj->every({}) }, 'every()' ) or note $@;
is( $rv, [
    $obj->new(
        id         => 42,
        data       => { model_id => 42, thx => 1138 },
        saved_data => { model_id => 42, thx => 1138 },
    ),
    $obj->new(
        id         => 43,
        data       => { model_id => 43, thx => 1139 },
        saved_data => { model_id => 43, thx => 1139 },
    ),
], 'every() data check' );

ok( lives { $rv = $obj->every_data({}) }, 'every_data()' ) or note $@;
is( $rv, [ { model_id => 42, thx => 1138 }, { model_id => 43, thx => 1139 } ], 'every_data() data check' );

is( $obj->resolve_id(1138), 1138, 'resolve_id(id)' );
is( $obj->resolve_id($obj), 42, 'resolve_id(obj)' );

isa_ok( $obj->resolve_obj($obj), 'Omniframe' );

done_testing;
