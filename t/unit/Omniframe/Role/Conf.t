use Test::Most;
use exact -conf;

my $obj;
use_ok('Omniframe');
lives_ok( sub { $obj = Omniframe->new->with_roles('+Conf') }, q{new->with_roles('+Conf')} );
ok( $obj->does('Omniframe::Role::Conf'), 'does Conf role' );
can_ok( $obj, 'conf' );
is( ref $obj->conf, 'Config::App', 'conf() is a Config::App' );

done_testing();
