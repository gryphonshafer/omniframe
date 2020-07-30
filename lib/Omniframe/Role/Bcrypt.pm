package Omniframe::Role::Bcrypt;

use exact -role;
use Digest;

with 'Omniframe::Role::Conf';

sub bcrypt ( $self, $input ) {
    my $conf = $self->conf->get('bcrypt');

    croak('Salt cannot remain as default value in application configuration')
        if ( $conf->{salt} eq '0123456789abcdef' );

    return Digest->new( 'Bcrypt', %$conf )->add($input)->hexdigest;
}

1;

=head1 NAME

Omniframe::Role::Bcrypt

=head1 SYNOPSIS

    package Package;

    use exact -class;

    with 'Omniframe::Role::Bcrypt';

    sub method ( $self, $input ) {
        return $self->bcrypt($input);
    }

=head1 DESCRIPTION

This role provides a single C<bcrypt> method which expects a value and will
return an encrypted output.

=head1 METHOD

=head2 bcrypt

This method expects some scalar input value and will return a one-way encrypted
result. It does this via L<Digest::Bcrypt>.

=head1 CONFIGURATION

The following is the default configuration, which must be overridden in the
application's configuration file. See L<Omniframe::Role::Conf>.

    bcrypt:
        cost: 1
        salt: 0123456789abcdef

If the salt remains unchanged, the method with throw an exception.

=head1 WITH ROLES

L<Omniframe::Role::Conf>.
