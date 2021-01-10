use Test2::V0;
use Omniframe::Control;

my $mock = mock 'Omniframe::Control' => (
    override => [ qw( setup_access_log debug info notice warning warn ) ],
);

my $obj;
ok( lives { $obj = Omniframe::Control->new }, 'new' ) or note $@;
isa_ok( $obj, $_ ) for ( 'Mojolicious', 'Omniframe' );
DOES_ok( $obj, "Omniframe::Role::$_" ) for ( qw( Conf Logging ) );

can_ok( $obj, qw(
    sass
    startup
    setup
    setup_access_log
    setup_mojo_logging
    setup_templating
    setup_static_paths
    setup_config
    setup_sockets
    setup_document
    preload_controllers
) );

done_testing;
