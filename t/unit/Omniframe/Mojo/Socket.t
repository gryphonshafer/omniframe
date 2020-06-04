use Test::Most;
use Test::MockModule;
use exact -conf;

my $log = Test::MockModule->new('Omniframe::Role::Logging');
$log->redefine( info => 1 );
$log->redefine( debug => 1 );

my $dq = Test::MockModule->new('DBIx::Query');
$dq->mock( $_ => sub { $_[0] } ) for ( qw( _connect do run sql ) );
$dq->mock( all => [] );
$dq->mock( value => 1 );

use_ok('Omniframe::Mojo::Socket');

my $obj;
lives_ok( sub { $obj = Omniframe::Mojo::Socket->new }, 'new' );
can_ok( $obj, $_ ) for ( qw( sockets setup event_handler ) );
ok( $obj->does("Omniframe::Role::$_"), "does $_ role" ) for ( qw( Conf Database Logging ) );

my $orig_sig_urg = $SIG{URG};
lives_ok( sub { $obj = $obj->setup }, 'setup' );
isnt( $orig_sig_urg, $SIG{URG}, 'URG handler set' );

my $event_handler;
lives_ok( sub { $event_handler = $obj->event_handler }, 'event_handler' );
is( ref($event_handler), 'CODE', 'event_handler set' );

done_testing();
