package Omniframe::Util::Bcrypt;

use exact -conf;
use Digest;

exact->exportable('bcrypt');

sub bcrypt ($input) {
    return Digest->new( 'Bcrypt', %{ conf->get('bcrypt') } )->add($input)->hexdigest;
}

1;

=head1 NAME

Omniframe::Util::Bcrypt

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::Data 'bcrypt';

    my $encrypted_input = bcrypt('input');

=head1 DESCRIPTION

This package provides an exportable utility function for encryption.

=head1 FUNCTION

=head2 bcrypt

This method expects some scalar input value and will return a one-way encrypted
result. It does this via L<Digest::Bcrypt>.

=head1 CONFIGURATION

The following is the default configuration, which should be overridden in the
application's configuration file. See L<Config::App>.

    bcrypt:
        cost: 5
        salt: 0123456789abcdef
