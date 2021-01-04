use Test::Most;
use Test::MockModule;
use exact -conf;

my $spurt;
my $mojo_file = Test::MockModule->new('Mojo::File');
$mojo_file->mock( spurt => sub { $spurt = $_[1] } );

use_ok('Omniframe::Util::Sass');

my $obj;
lives_ok( sub { $obj = Omniframe::Util::Sass->new }, 'new' );
isa_ok( $obj, 'Omniframe::Util::Sass' );
ok( $obj->does('Omniframe::Role::Conf'), 'does Conf role' );
can_ok( $obj, qw( mode scss_src compile_to report_cb error_cb build exists ) );

lives_ok( sub { $obj->build }, 'build succeeeds' );
is( substr( $spurt, 0, 3 ), '/* ', 'CSS rendered in dev mode' );

lives_ok( sub { $obj->mode('production') }, 'set production mode' );
lives_ok( sub { $obj->build }, 'build succeeeds again' );
isnt( substr( $spurt, 0, 3 ), '/* ', 'CSS rendered not in dev mode' );

ok(
    $obj->exists(
        join( '/',
            $obj->conf->get( qw( config_app root_dir ) ),
            'config/assets/sass/foundation',
        )
    ),
    'exists() success',
);
ok( ( not $obj->exists('does_not_exist') ), 'exists() failure' );

$obj->scss_src(
    join( '/',
        $obj->conf->get( qw( config_app root_dir ) ),
        'cpanfile',
    )
);

throws_ok(
    sub {
        $obj->build(
            sub {},
            sub ($error) { die $error . "\n" },
        )
    },
    qr/^Error: expected "\{"/,
    'build fails on non-SASS',
);

done_testing();
