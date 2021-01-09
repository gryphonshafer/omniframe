use Test2::V0;
use exact -conf;
use Omniframe;

my $obj;
ok( lives { $obj = Omniframe->new->with_roles('+Conf') }, q{new->with_roles('+Conf')} ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Conf' );
can_ok( $obj, 'conf' );
is( ref $obj->conf, 'Config::App', 'conf() is a Config::App' );

done_testing;
