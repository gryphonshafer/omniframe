package Omniframe::Util::Crypt;

use exact -conf;
use Crypt::CBC;
use MIME::Base64 qw( encode_base64 decode_base64 );

exact->exportable( qw( encrypt decrypt ) );

my $conf   = conf->get('crypt');
my $cipher = Crypt::CBC->new( map {
    '-' . $_ => ( $_ eq 'salt' ) ? decode_base64( $conf->{$_} ) : $conf->{$_}
} keys %$conf );

sub encrypt ($input) {
    return encode_base64( $cipher->encrypt($input) );
}

sub decrypt ($input) {
    return $cipher->decrypt( decode_base64($input) );
}

1;

=head1 NAME

Omniframe::Util::Crypt

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::Crypt qw( encrypt decrypt );

    my $payload = 'Some scalar data payload...';

    my $encrypted_text = encrypt($payload);
    my $decrypted_data = decrypt($encrypted_text);

=head1 DESCRIPTION

This package provides a exportable utility functions for encryption and
decryption. It does this via L<Crypt::CBC>.

=head1 FUNCTIONS

=head2 encrypt

This method expects some scalar input value and will return a print-safe
encrypted output.

    my $encrypted_text = encrypt($payload);

=head2 decrypt

This method expects a scalar input value generated from C<encrypt> and will
return the decrypted/original data.

    my $decrypted_data = decrypt($encrypted_text);

=head1 CONFIGURATION

The following is the default configuration, which should be overridden in the
application's configuration file. See L<Config::App>.

    crypt:
        pass: passphrase
        salt: 0123456789a
        pbkdf: pbkdf2
        chain_mode: cbc
        cipher: Cipher::AES
        iter: 10000
        hasher: HMACSHA2
        header: salt
        padding: standard
