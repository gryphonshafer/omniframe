use Test2::V0;
use exact -conf;
use Omniframe::Util::Crypt qw( encrypt decrypt urand );

imported_ok( qw( encrypt decrypt urand ) );

my $payload   = 'Some scalar data payload...';
my $encrypted = encrypt($payload);
my $decrypted = decrypt($encrypted);

isnt( $payload, $encrypted, 'encrypt' );
is( $payload, $decrypted, 'decrypt' );

my $rand = urand( 10 - 1 ) + 1;
ok( ( $rand >= 1 and $rand <= 10 ), 'urand' );

done_testing;
