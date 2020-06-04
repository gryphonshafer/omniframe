use Test::Most;
use Test::MockModule;
use exact -conf;

my $break = 1;

my $inotify = Test::MockModule->new('Linux::Inotify2');
$inotify->mock( 'poll' => sub { $break = 0 } );

use_ok('Omniframe::Util::Watch');

my $obj;
lives_ok( sub { $obj = Omniframe::Util::Watch->new }, 'new' );
can_ok( $obj, 'watch' );

lives_ok(
    sub {
        $obj->watch(
            sub {},
            conf->get( qw( config_app root_dir ) ),
            \$break,
        )
    },
    'watch',
);

done_testing();
