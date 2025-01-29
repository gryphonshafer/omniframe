use Test2::V0;
use exact;
use Test::Output;
use Omniframe;

my $obj;
ok( lives { $obj = Omniframe->with_roles('+Output')->new }, q{with_roles('+Output')->new} ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Output' );
can_ok( $obj, 'dp' );

done_testing;
