use exact -conf;
use Omniframe::Test::App;

setup;

mojo->get_ok('/devdocs')
    ->status_is(200)
    ->header_is( 'content-type' => 'text/html;charset=UTF-8' )
    ->text_is( title => 'Omniframe DevDocs' )
    ->text_is( 'ul li a[href="/devdocs/Omniframe/lib/Omniframe/Control.pm"]' => 'Omniframe::Control' );

mojo->get_ok('/devdocs/Omniframe/lib/Omniframe/Control.pm')
    ->status_is(200)
    ->header_is( 'content-type' => 'text/html;charset=UTF-8' )
    ->text_is( title => 'Omniframe DevDocs: lib/Omniframe/Control.pm' )
    ->text_is( 'div.pod h1 ~ p' => 'Omniframe::Control' );

teardown;
