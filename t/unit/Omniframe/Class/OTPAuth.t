use Test2::V0;
use exact -conf;
use Omniframe::Class::OTPAuth;

my $otpauth   = Omniframe::Class::OTPAuth->new;
my $generated = $otpauth->generate('example@example.com');

is(
    $generated,
    hash {
        field qr_code_png => T();
        field secret32    => match(qr|^[a-z0-9]{16}$|);
        field otpauth     => match(
            qr|^otpauth://totp/Omniframe:example%40example\.com\?secret=[a-z0-9]{16}\&issuer=Omniframe$|
        );
    },
    'generate',
);

is(
    $otpauth->verify(
        $otpauth->auth->code( $generated->{secret32} ),
        $generated->{secret32},
    ),
    1,
    'verify',
);

done_testing;
