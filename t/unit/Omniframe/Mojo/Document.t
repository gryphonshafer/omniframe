use Test2::V0;
use exact -conf;
use Omniframe::Mojo::Document;

my $mock = mock 'Omniframe::Mojo::Document' => ( override => 'notice' );

my $obj;
ok( lives { $obj = Omniframe::Mojo::Document->new }, 'new' ) or note $@;
can_ok( $obj, 'helper' );
DOES_ok( $obj, "Omniframe::Role::$_" ) for ( qw( Conf Logging ) );

my $helper;
ok( lives { $helper = $obj->helper }, 'helper' ) or note $@;
ref_ok( $helper, 'CODE', 'helper set' );

done_testing;
