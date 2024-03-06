use exact -conf;
use Omniframe::Test::App;

setup;

mojo
    ->websocket_ok('/ws')
    ->send_ok( 'y' x 50000 )
    ->finish_ok;

teardown;
