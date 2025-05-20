use Test2::V0;
use exact -conf;
use Omniframe::Test::App;

setup;

mojo->get_ok('/test.js')
    ->status_is(200)
    ->header_is( 'content-type' => 'application/javascript;name=browser_test.js' )
    ->content_like( qr/^'use strict';\n/ );

mojo->get_ok('/docs/README.md')
    ->status_is(200)
    ->text_is( 'h1#omniframe', 'Omniframe' );

mojo->get_ok('/docs/DOES_NOT_EXIST')->status_is(404);

my $docs_nav = mojo->app->docs_nav;

is(
    $docs_nav->[0],
    {
        href  => '/',
        name  => 'Home Page',
        title => 'Home Page',
        type  => 'md',
    },
    'docs_nav 0',
);

is(
    $docs_nav->[1],
    {
        href  => '/README.md',
        name  => 'README',
        title => 'Omniframe',
        type  => 'md',
    },
    'docs_nav 1',
);

teardown;
