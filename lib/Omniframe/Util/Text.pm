package Omniframe::Util::Text;

use exact;

exact->exportable( qw{ deat trim } );

sub deat ($error) {
    $error = reverse $error;
    $error =~ s/^\s*\.\d+\s+enil\s+.+?\s+ta\s+//g;
    $error = reverse $error;
    return $error;
}

sub trim (@input) {
    for (@input) {
        s/\s{2,}/ /g;
        s/(^\s+|\s+$)//g;
    }

    return
        (wantarray) ? @input :
        ( @input > 1 ) ? \@input : $input[0];
}

1;

=head1 NAME

Omniframe::Role::Text

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::Text qw( deat trim );

    say deat('Something bad happened at /some/place.pl line 42.');
    # prints "Something bad happened"

    say trim(' Stuff   and things ');
    # prints "Stuff and things"

=head1 DESCRIPTION

This package provides exportable utility functions for text.

=head1 FUNCTION

=head2 deat

This method removes any "at /some/place.pl line 42." instances from the end of
any string passed in.

=head2 trim

This function accepts a string and returns that string after collapsing all
multiple spaces within to single spaces and removing spacing on the edges.
