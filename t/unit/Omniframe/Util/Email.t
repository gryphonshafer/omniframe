use Test::Most;
use Test::MockModule;
use exact;

my $log = Test::MockModule->new('Omniframe::Role::Logging');
$log->redefine( 'info', 1 );

my $mailer = Test::MockModule->new('Email::Mailer');
$mailer->redefine( 'send', 1 );

my $obj;
use_ok('Omniframe::Util::Email');

throws_ok(
    sub { $obj = Omniframe::Util::Email->new() },
    qr/Failed new\(\) because "type" must be defined/,
    'new() throws',
);
lives_ok( sub { $obj = Omniframe::Util::Email->new( type => 'example' ) }, 'new( type => $type )' );
isa_ok( $obj, $_ ) for ( qw( Omniframe::Util::Email Omniframe ) );
ok( $obj->does("Omniframe::Role::$_"), "does $_ role" ) for ( qw( Template Logging ) );
can_ok( $obj, qw( type subject html new send ) );
lives_ok( sub { $obj->send({}) }, 'send()' );

done_testing();
