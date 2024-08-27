use Test2::V0;
use DBD::SQLite;
use Omniframe::Mojo::Socket;

my $mock_logging = mock 'Omniframe::Role::Logging' => ( set => [ qw( info debug ) ] );
my $mock_dbixc   = mock 'DBIx::Query'              => (
    set => [
        all   => sub { [] },
        value => 1,
        quote => sub { shift; DBD::SQLite::db->quote(@_) },
        map { $_ => sub { $_[0] } } qw(
            _connect do run sql sqlite_enable_load_extension sqlite_load_extension
        ),
    ],
);

my $obj;
ok( lives { $obj = Omniframe::Mojo::Socket->new }, 'new' ) or note $@;
can_ok( $obj, $_ ) for ( qw( sockets setup event_handler ) );
DOES_ok( $obj, "Omniframe::Role::$_" ) for ( qw( Conf Database Logging ) );

my $orig_sig_urg = $SIG{URG};
ok( lives { $obj = $obj->setup }, 'setup' ) or note $@;
isnt( $orig_sig_urg, $SIG{URG}, 'URG handler set' );

my $event_handler;
ok( lives { $event_handler = $obj->event_handler }, 'event_handler' ) or note $@;
ref_ok( $event_handler, 'CODE', 'event_handler set' );

done_testing;
