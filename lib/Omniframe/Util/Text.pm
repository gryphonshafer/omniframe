package Omniframe::Util::Text;

use exact;

exact->exportable('trim');

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
    use Omniframe::Util::Text 'trim';

    say trim(' Stuff   and things ');
    # prints "Stuff and things"

=head1 DESCRIPTION

This package provides exportable utility functions for text.

=head1 FUNCTION

=head2 trim

This function accepts a string and returns that string after collapsing all
multiple spaces within to single spaces and removing spacing on the edges.
