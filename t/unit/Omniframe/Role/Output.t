use Test2::V0;
use Test::Output;
use Omniframe;

my $obj;
ok( lives { $obj = Omniframe->with_roles('+Output')->new }, q{with_roles('+Output')->new} ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Output' );
can_ok( $obj, qw( dp deat ) );
is( $obj->deat('Something bad happened at /some/place.pl line 42.'), 'Something bad happened', 'deat' );

done_testing;
