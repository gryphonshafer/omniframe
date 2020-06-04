use Test::Most;
use Test::Mojo;
use Test::MockModule;
use exact -conf;

$ENV{MOJO_LOG_LEVEL} = 'error';
Test::MockModule->new('Omniframe::Control')->redefine( 'setup_access_log', 1 );

Test::Mojo->new('Omniframe::Control')->get_ok('/api', json => { answer => 42 } )
    ->status_is(200)
    ->header_is( 'content-type' => 'application/json;charset=UTF-8' )
    ->json_is( '/request/answer', 42, 'JSON return data correct' );

done_testing();
