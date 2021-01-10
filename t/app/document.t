use Test2::V0;
use Test2::MojoX;
use Omniframe::Control;

$ENV{MOJO_LOG_LEVEL} = 'error';

my $mock = mock 'Omniframe::Control' => (
    override => [ qw( setup_access_log debug info notice warning warn ) ],
);

Test2::MojoX->new('Omniframe::Control')->get_ok('/test.js')
    ->status_is(200)
    ->header_is( 'content-type' => 'application/javascript;name=browser_test.js' )
    ->content_like( qr/^'use strict';\n/ );

done_testing;
