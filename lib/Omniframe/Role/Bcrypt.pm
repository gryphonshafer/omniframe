package Omniframe::Role::Bcrypt;

use exact -role, -conf;
use Digest;

sub bcrypt ( $self, $input ) {
    return Digest->new( 'Bcrypt', %{ conf->get('bcrypt') } )->add($input)->hexdigest;
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

The following is the default configuration, which should be overridden in the
application's configuration file. See L<Config::App>.

    bcrypt:
        cost: 5
        salt: 0123456789abcdef
