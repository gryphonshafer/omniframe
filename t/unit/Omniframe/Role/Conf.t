use Test2::V0;
use Omniframe;

my $obj;
ok( lives { $obj = Omniframe->with_roles('+Conf')->new }, q{with_roles('+Conf')->new} ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Conf' );
can_ok( $obj, 'conf' );
is( ref $obj->conf, 'Config::App', 'conf() is a Config::App' );

done_testing;
