use Test2::V0;
use exact -conf;
use Omniframe::Util::Data qw( dataload deepcopy node_descend );

imported_ok( qw( dataload deepcopy node_descend ) );

ref_ok( dataload('config/app.yaml'), 'HASH', 'YAML data decoded' );

my $data_0    = { thx => 1138, answer => 42 };
my $data_1    = { data => $data_0 };
my $data_copy = [
    {
        thx    => 1138,
        answer => 42,
    },
    {
        data => {
            answer => 42,
            thx    => 1138,
        },
    },
];

my ( $deepcopy, @deepcopy );

ok( lives { $deepcopy = deepcopy( $data_0, $data_1 ) }, 'deepcopy to scalar' ) or note $@;
ok( lives { @deepcopy = deepcopy( $data_0, $data_1 ) }, 'deepcopy to array'  ) or note $@;

is ( $deepcopy,  $data_copy, 'deepcopy to scalar data check' );
is ( \@deepcopy, $data_copy, 'deepcopy to array data check'  );

is (
    node_descend(
        [ { thx => 1138 }, { answer => 42 }, { combination => 12345 } ],
        [ 'post', 'hash', sub ($node) { $node->{touched} = 1 } ],
    ),
    [ { thx => 1138, touched => 1 }, { answer => 42, touched => 1 }, { combination => 12345, touched => 1 } ],
    'node_descend',
);

is (
    node_descend(
        [ { thx => 1138 }, { answer => 42 } ],
        [ 'wrap', 'hash', sub ( $node, $callback ) {
            $node->{touched} = 1;
            $callback->();
        } ],
    ),
    [ { thx => 1138, touched => 1 }, { answer => 42, touched => 1 } ],
    'node_descend',
);

done_testing;
