use Test2::V0;
use exact -conf;
use Omniframe::Control;

my $mock = mock 'Omniframe::Control' => (
    override => [ qw( setup_access_log setup_performance_log debug info notice warning warn ) ],
);

my $obj;
ok( lives { $obj = Omniframe::Control->new }, 'new' ) or note $@;
isa_ok( $obj, $_ ) for ( 'Mojolicious', 'Omniframe' );
DOES_ok( $obj, "Omniframe::Role::$_" ) for ( qw( Logging Template ) );

can_ok( $obj, qw(
    sass
    startup
    setup
    setup_mojo_logging
    setup_access_log
    setup_performance_log
    setup_request_base
    setup_samesite
    setup_csrf
    setup_sass_build
    setup_templating
    setup_static_paths
    setup_config
    setup_packer
    setup_compressor
    setup_sockets
    setup_document
    setup_devdocs
    setup_preload_controllers
) );

done_testing;
