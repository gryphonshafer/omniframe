use Test2::V0;
use Omniframe;

ok( lives { Omniframe->new }, 'new' ) or note $@;

done_testing;
