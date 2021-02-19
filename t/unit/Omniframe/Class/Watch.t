use Test2::V0;
use exact -conf;
use Omniframe::Class::Watch;

my $break = 1;
my $mock  = mock 'Linux::Inotify2' => ( override => [ poll => sub { $break = 0 } ] );

my $obj;
ok( lives { $obj = Omniframe::Class::Watch->new }, 'new' ) or note $@;
can_ok( $obj, 'watch' );

ok(
    lives {
        $obj->watch(
            sub {},
            conf->get( qw( config_app root_dir ) ),
            \$break,
        )
    },
    'watch',
) or note $@;

done_testing;
