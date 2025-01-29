use Test2::V0;
use exact -conf;
use Omniframe::Util::Data qw( dataload deepcopy );

imported_ok( qw( dataload deepcopy ) );

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

done_testing;
