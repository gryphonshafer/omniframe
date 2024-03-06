use exact -conf;
use Omniframe::Test::App;

setup;

mojo->new('Project::Control')->get_ok('/')
    ->status_is(200)
    ->header_is( 'content-type' => 'text/html;charset=UTF-8' )
    ->text_is( title => 'Example Page' )
    ->attr_like( 'link[rel="stylesheet"]:last-of-type', 'href', qr|\bapp.css\?version=\d+| );

teardown;
