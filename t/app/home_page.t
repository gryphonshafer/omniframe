use Test::Most;
use Test::Mojo;
use Test::MockModule;
use exact -conf;

$ENV{MOJO_LOG_LEVEL} = 'error';
my $mock = Test::MockModule->new('Omniframe::Control');
$mock->redefine( $_, 1 ) for ( qw( setup_access_log debug info notice warning warn ) );

Test::Mojo->new('Project::Control')->get_ok('/')
    ->status_is(200)
    ->header_is( 'content-type' => 'text/html;charset=UTF-8' )
    ->text_is( title => 'Example Page' )
    ->attr_like( 'link[rel="stylesheet"]:last-of-type', 'href', qr|\bapp.css\?version=\d+| );

done_testing();
