use Test::Most;
use Test::Mojo;
use Test::MockModule;
use exact -conf;

$ENV{MOJO_LOG_LEVEL} = 'error';
my $mock = Test::MockModule->new('Omniframe::Control');
$mock->redefine( $_, 1 ) for ( qw( setup_access_log debug info notice warning warn ) );

Test::Mojo->new('Omniframe::Control')->get_ok('/test.js')
    ->status_is(200)
    ->header_is( 'content-type' => 'application/javascript;name=browser_test.js' )
    ->content_like( qr/^'use strict';\n/ );

done_testing();
