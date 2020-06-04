use Test::Most;
use exact;

use_ok('Omniframe');
lives_ok( sub { Omniframe->new }, 'new' );

done_testing();
