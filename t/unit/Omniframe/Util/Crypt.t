use Test2::V0;
use exact -conf;
use Omniframe::Util::Crypt qw( encrypt decrypt );

imported_ok( qw( encrypt decrypt ) );

my $payload   = 'Some scalar data payload...';
my $encrypted = encrypt($payload);
my $decrypted = decrypt($encrypted);

isnt( $payload, $encrypted, 'encrypt' );
is( $payload, $decrypted, 'decrypt' );

done_testing;
