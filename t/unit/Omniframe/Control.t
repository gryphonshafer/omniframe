use Test::Most;
use exact;

my $obj;
use_ok('Omniframe::Control');
lives_ok( sub { $obj = Omniframe::Control->new }, 'new()' );
isa_ok( $obj, $_ ) for ( 'Mojolicious', 'Omniframe' );
ok( $obj->does("Omniframe::Role::$_"), "does $_ role" ) for ( qw( Conf Logging ) );

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

done_testing();
