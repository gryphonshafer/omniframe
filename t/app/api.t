use Test2::V0;
use Test2::MojoX;
use exact -conf;
use Omniframe::Control;

$ENV{MOJO_LOG_LEVEL} = 'error';

my $mock = mock 'Omniframe::Control' => (
    override => [ qw( setup_access_log debug info notice warning warn ) ],
);

Test2::MojoX->new('Omniframe::Control')->get_ok('/api', json => { answer => 42 } )
    ->status_is(200)
    ->header_is( 'content-type' => 'application/json;charset=UTF-8' )
    ->json_is( '/request/answer', 42, 'JSON return data correct' );

done_testing;
