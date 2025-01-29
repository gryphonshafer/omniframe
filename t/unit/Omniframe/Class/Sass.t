use Test2::V0;
use exact -conf;
use Omniframe::Class::Sass;

my ( $spew, $obj );
my $mock = mock 'Mojo::File' => ( override => [ spew => sub { $spew = $_[1] } ] );

ok( lives { $obj = Omniframe::Class::Sass->new }, 'new' ) or note $@;
isa_ok( $obj, 'Omniframe::Class::Sass' );
can_ok( $obj, qw( mode scss_src compile_to report_cb error_cb build exists ) );

ok( lives { $obj->build }, 'build succeeeds' ) or note $@;
is( substr( $spew, 0, 3 ), '/* ', 'CSS rendered in dev mode' );

ok( lives { $obj->mode('production') }, 'set production mode' ) or note $@;
ok( lives { $obj->build }, 'build succeeeds again' ) or note $@;
isnt( substr( $spew, 0, 3 ), '/* ', 'CSS rendered not in dev mode' );

ok(
    $obj->exists(
        join( '/',
            conf->get( qw( config_app root_dir ) ),
            'config/assets/sass/base',
        )
    ),
    'exists() success',
);
ok( ( not $obj->exists('does_not_exist') ), 'exists() failure' );

$obj->scss_src(
    join( '/',
        conf->get( qw( config_app root_dir ) ),
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
