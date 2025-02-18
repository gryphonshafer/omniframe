package Omniframe::Class::OTPAuth;

use exact -conf, 'Omniframe';
use Auth::GoogleAuth;
use Imager::QRCode;

has issuer => sub { conf->get( qw( otpauth issuer ) ) };
has range  => sub { conf->get( qw( otpauth range ) ) };
has auth   => sub { return Auth::GoogleAuth->new };
has imager => sub {
    my $imager = conf->get( qw( otpauth imager ) );
    $imager->{$_} = Imager::Color->new( $imager->{$_}->@* ) for ( qw( lightcolor darkcolor ) );
    return Imager::QRCode->new(%$imager);
};

sub generate ( $self, $key_id ) {
    my $otpauth  = $self->auth->otpauth( undef, $key_id, $self->issuer );
    my $secret32 = $self->auth->secret32;

    $self->auth->clear;

    my $qr_code_png;
    open( my $qr_code_filehandle, '>', \$qr_code_png ) or croak $!;

    my $img = $self->imager->plot($otpauth);
    $img->write( fh => $qr_code_filehandle, type => 'png' ) or croak $img->errstr;

    return {
        secret32    => $secret32,
        otpauth     => $otpauth,
        qr_code_png => $qr_code_png,
    };
}

sub verify ( $self, $code, $secret32 ) {
    my $result = $self->auth->verify( $code, $self->range, $secret32 );
    $self->auth->clear;
    return $result;
}

1;

=head1 NAME

Omniframe::Class::OTPAuth

=head1 SYNOPSIS

    use exact;
    use Omniframe::Class::OTPAuth;

    my $otpauth = Omniframe::Class::OTPAuth->new;

    my $key_id    = 'example@example.com';
    my $generated = $otpauth->generate($key_id);
    # returns a hashref: { secret32 otpauth qr_code_png }

    my ( $code, $secret32 ) = ( '357905', 'xvsai4hytyyioqwl' );
    my $success_boolean = $otpauth->verify( $code, $secret32 );

=head1 DESCRIPTION

This class provides a simplified interface for 2FA TOTP via use of
L<Auth::GoogleAuth> and L<Imager::QRCode>, using configuration settings.

The following is an example of how to generate and render a QR code, assuming
that a C<user> L<Omniframe::Role::Model> object is stored in the stash.

    use Omniframe::Class::OTPAuth;
    my $otpauth = Omniframe::Class::OTPAuth->new;

    sub controller_action_for_generating_and_rendering_qr_code ($self) {
        my $generated = $otpauth->generate( $self->param('key_id') );
        $self->stash('user')->save({ secret32 => $generated->{secret32} });
        return $c->render( data => $generated->{qr_code_png}, format => 'png' );
    }

=head1 METHODS

=head2 generate

Requires a key ID, used by L<Auth::GoogleAuth>. Returns a hashref containing
the keys C<secret32>, C<otpauth>, and C<qr_code_png>. C<secret32> is a base-32
encoded copy of the secret string. C<otpauth> is the URL that's embedded in the
C<qr_code_png> binary data, which is in PNG format.

    my $key_id    = 'example@example.com';
    my $generated = $otpauth->generate($key_id);
    # returns a hashref: { secret32 otpauth qr_code_png }

=head2 verify

Requires a TOTP value (6-digit code) and a C<secret32> value. Returns a true or
false value representing successful verification.

    my ( $code, $secret32 ) = ( '357905', 'xvsai4hytyyioqwl' );
    my $success_boolean = $otpauth->verify( $code, $secret32 );

=head1 CONFIGURATION

The following is the default configuration, which can be overridden in the
application's configuration file. See L<Config::App>.

    otpauth:
        issuer: Omniframe
        range : 1
        imager:
            size          : 4
            margin        : 2
            level         : M
            version       : 6
            casesensitive : 0
            mode          : 8-bit
            lightcolor    : [ 255, 255, 255 ]
            darkcolor     : [ 0, 0, 0 ]

=head1 INHERITANCE

L<Omniframe>.
