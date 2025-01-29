use Test2::V0;
use exact;
use Omniframe::Class::Email;

my $mock_email  = mock 'Omniframe::Class::Email' => ( override => 'info' );
my $mock_mailer = mock 'Email::Mailer'           => ( override => 'send' );

my $obj;

like(
    dies { $obj = Omniframe::Class::Email->new() },
    qr/Failed new\(\) because "type" must be defined/,
    'new() throws',
);
ok( lives { $obj = Omniframe::Class::Email->new( type => 'example' ) }, 'new( type => $type )' ) or note $@;
isa_ok( $obj, $_ ) for ( qw( Omniframe::Class::Email Omniframe ) );
DOES_ok( $obj, "Omniframe::Role::$_" ) for ( qw( Template Logging ) );
can_ok( $obj, qw( type subject html new send ) );
ok( lives { $obj->send({}) }, 'send()' ) or note $@;

done_testing;
