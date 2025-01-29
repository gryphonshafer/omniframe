use Test2::V0;
use exact -conf;
use Omniframe;

my $obj;
ok( lives { $obj = Omniframe->with_roles('+Bcrypt')->new }, q{with_roles('+Bcrypt')->new} ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Bcrypt' );
can_ok( $obj, 'bcrypt' );

done_testing;
