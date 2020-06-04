use Test::Most;
use Test::MockModule;
use exact -conf;

my $log = Test::MockModule->new('Omniframe::Role::Logging');
$log->redefine( notice => 1 );

use_ok('Omniframe::Mojo::Document');

my $obj;
lives_ok( sub { $obj = Omniframe::Mojo::Document->new }, 'new' );
can_ok( $obj, 'helper' );
ok( $obj->does("Omniframe::Role::$_"), "does $_ role" ) for ( qw( Conf Logging ) );

my $helper;
lives_ok( sub { $helper = $obj->helper }, 'helper' );
is( ref($helper), 'CODE', 'helper set' );

done_testing();
