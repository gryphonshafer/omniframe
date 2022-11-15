use Test2::V0;
use Omniframe;

my $obj;
ok( lives { $obj = Omniframe->with_roles('+Time')->new }, q{with_roles('+Time')->new} ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Time' );
can_ok( $obj, 'time' );
is( ref $obj->time, 'Omniframe::Class::Time', 'time() is a Omniframe::Class::Time' );

done_testing;
