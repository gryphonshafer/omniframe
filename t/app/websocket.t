use Test2::V0;
use Test2::MojoX;
use exact -conf;
use Omniframe::Control;

conf->put( qw( logging log_level ), $_ => 'error' ) for ( qw( production development ) );

my $mock = mock 'Omniframe::Control' => ( override => 'setup_access_log' );

Test2::MojoX->new('Omniframe::Control')
    ->websocket_ok('/ws')
    ->send_ok( 'y' x 50000 )
    ->finish_ok;

done_testing;
