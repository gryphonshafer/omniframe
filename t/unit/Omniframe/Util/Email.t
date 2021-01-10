use Test2::V0;
use Omniframe::Util::Email;

my $mock_email  = mock 'Omniframe::Util::Email' => ( override => 'info' );
my $mock_mailer = mock 'Email::Mailer'          => ( override => 'send' );

my $obj;

like(
    dies { $obj = Omniframe::Util::Email->new() },
    qr/Failed new\(\) because "type" must be defined/,
    'new() throws',
);
ok( lives { $obj = Omniframe::Util::Email->new( type => 'example' ) }, 'new( type => $type )' ) or note $@;
isa_ok( $obj, $_ ) for ( qw( Omniframe::Util::Email Omniframe ) );
ok( $obj->does("Omniframe::Role::$_"), "does $_ role" ) for ( qw( Template Logging ) );
can_ok( $obj, qw( type subject html new send ) );
ok( lives { $obj->send({}) }, 'send()' ) or note $@;

done_testing;
