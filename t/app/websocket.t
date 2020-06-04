use Test::Most;
use Test::Mojo;
use Test::MockModule;
use exact -conf;

conf->put( qw( logging log_level ), $_ => 'error' ) for ( qw( production development ) );
Test::MockModule->new('Omniframe::Control')->redefine( 'setup_access_log', 1 );

Test::Mojo->new('Omniframe::Control')
    ->websocket_ok('/ws')
    ->send_ok( 'y' x 50000 )
    ->finish_ok;

done_testing();
