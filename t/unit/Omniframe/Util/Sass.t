use Test2::V0;
use exact -conf;
use Omniframe::Util::Sass;

my ( $spurt, $obj );
my $mock = mock 'Mojo::File' => ( override => [ spurt => sub { $spurt = $_[1] } ] );

ok( lives { $obj = Omniframe::Util::Sass->new }, 'new' ) or note $@;
isa_ok( $obj, 'Omniframe::Util::Sass' );
DOES_ok( $obj, 'Omniframe::Role::Conf' );
can_ok( $obj, qw( mode scss_src compile_to report_cb error_cb build exists ) );

ok( lives { $obj->build }, 'build succeeeds' ) or note $@;
is( substr( $spurt, 0, 3 ), '/* ', 'CSS rendered in dev mode' );

ok( lives { $obj->mode('production') }, 'set production mode' ) or note $@;
ok( lives { $obj->build }, 'build succeeeds again' ) or note $@;
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

like(
    dies {
        $obj->build(
            sub {},
            sub ($error) { die $error . "\n" },
        )
    },
    qr/^Error: expected "\{"/,
    'build fails on non-SASS',
);

done_testing;
