#!/usr/bin/env perl
use Cwd 'cwd';
use FindBin;
BEGIN { $FindBin::Bin = cwd(); }

use exact -cli, -conf;
use Mojo::JSON 'decode_json', 'encode_json';
use Omniframe::Class::Email;

my $opt = options( qw{ recipient|r=s type|t=s data|d=s } );
pod2usage('Must provide "recipient" email address') unless ( $opt->{recipient} );
pod2usage('Must set email "type" to use') unless ( $opt->{type} );

Omniframe::Class::Email->new( type => $opt->{type} )->send({
    to   => $opt->{recipient},
    data => ( ( $opt->{data} ) ? decode_json( $opt->{data} ) : {} ),
});

=head1 NAME

email_send.pl - Send an email via Omniframe::Class::Email

=head1 SYNOPSIS

    email_send.pl OPTIONS
        -r, --recipient EMAIL_ADDRESS  # recipient email address
        -t, --type      EMAIL_TYPE     # email type name
        -d, --data      JSON_DATA      # optional data for the template
        -h, --help
        -m, --man

=head1 DESCRIPTION

This program will send an email via L<Omniframe::Class::Email>.

=head1 OPTIONS

=head2 -r, --recipient

The C<to> email address string.

=head2 -t, --type

The email template type, as per L<Omniframe::Class::Email>.

=head2 -d, --data

An optional JSON string of data to use for the template.
