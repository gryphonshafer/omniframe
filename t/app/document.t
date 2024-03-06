use exact -conf;
use Omniframe::Test::App;

setup;

mojo->get_ok('/test.js')
    ->status_is(200)
    ->header_is( 'content-type' => 'application/javascript;name=browser_test.js' )
    ->content_like( qr/^'use strict';\n/ );

teardown;
