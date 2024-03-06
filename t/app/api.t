use exact -conf;
use Omniframe::Test::App;

setup;

mojo->get_ok( '/api', json => { answer => 42 } )
    ->status_is(200)
    ->header_is( 'content-type' => 'application/json;charset=UTF-8' )
    ->json_is( '/request/answer', 42, 'JSON return data correct' );

teardown;
