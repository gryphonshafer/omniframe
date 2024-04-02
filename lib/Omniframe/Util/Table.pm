package Omniframe::Util::Table;

use exact;
use Text::Table::Tiny 'generate_table';

exact->exportable('table');

sub table (@input) {
    croak 'table() input missing or malformed' if ( not @input or @input > 1 and @input % 2 );

    my $input = ( @input == 1 ) ? { rows => @input } : {@input};
    croak 'table requires rows data' unless ( ref $input->{rows} eq 'ARRAY' );

    $input->{cols}     //= [ sort keys $input->{rows}[0]->%* ] if ( ref $input->{rows}[0] eq 'HASH' );
    $input->{acronyms} //= ['id'];

    for my $col ( $input->{cols}->@* ) {
        $col = [$col] unless ( ref $col and @$col != 1 );

        splice( @$col, 1, 0, undef )
            if ( not defined $col->[1] or $col->[1] ne 'l' and $col->[1] ne 'c' and $col->[1] ne 'r' );

        push( @$col, join( ' ', map {
            ( /A-Z/ ) ? $_ : do {
                my $key = $_;
                ( grep { $key eq $_ } $input->{acronyms}->@* ) ? uc $_ : ucfirst $_;
            }
        } split( /_+/, $col->[0] ) ) ) if ( @$col == 2 );

        push( $input->{keys}->@*,   $col->[0] );
        push( $input->{align}->@*,  $col->[1] );
        push( $input->{labels}->@*, $col->[2] );
    }

    $input->{rows} = [
        map {
            ( ref $_ eq 'HASH' ) ? [ do {
                my $row = $_;
                map { $row->{$_} } $input->{keys}->@*;
            } ] : $_;
        }
        $input->{rows}->@*
    ];

    for ( my $i = 0; $i < $input->{rows}[0]->@*; $i++ ) {
        $input->{align}[$i] //= ( $input->{rows}[0][$i] =~ /^[\d,.]+$/ ) ? 'r' : 'l';
    }

    my $table = generate_table(
        maybe header => $input->{labels},
        align        => $input->{align},
        rows         => $input->{rows},
        maybe style  => $input->{style},
        top_and_tail => ( ( not $input->{style} ) ? 1 : 0 ),
    );

    return $table if ( $input->{style} or not $input->{labels} );

    my @table = split( /\n/, $table );
    $table[1] =~ s/\+/\|/g;

    my @seperator = split( /\|/, substr( $table[1], 1 ) );
    for ( my $i = 0; $i < @seperator; $i++ ) {
        $seperator[$i] = ':' . substr( $seperator[$i], 1 ) if ( $input->{align}[$i] eq 'c' );
        $seperator[$i] = substr( $seperator[$i], 0, length( $seperator[$i] ) - 1 ) . ':'
            if ( $input->{align}[$i] eq 'r' or $input->{align}[$i] eq 'c' );
    }

    $table[1] = '|' . join( '|', @seperator ) . '|';

    return join( "\n", @table );
}

1;

=head1 NAME

Omniframe::Util::Table

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::Table 'table';

    # simple table no header
    say table( [ [ 1, 2, 3 ], [ 4, 5, 6 ] ] );
    # | 1 | 2 | 3 |
    # | 4 | 5 | 6 |

    # table with header
    say table( [
        { alpha => 1, bravo => 2, charlie_delta => 'Stuff and Things' },
        { alpha => 4, bravo => 5, charlie_delta => 'Things and Stuff and More' },
    ] );
    # | Alpha | Bravo | Charlie Delta             |
    # |------:|------:|---------------------------|
    # |     1 |     2 | Stuff and Things          |
    # |     4 |     5 | Things and Stuff and More |

    # table with header and defined columns
    say table(
        rows => [
            { thing => 'Thing 1',  x => 2048, stuff_things => 'Stuff',  user_id => 1138 },
            { thing => 'Thing 16', x =>   16, stuff_things => 'Things', user_id => 1024 },
        ],
        cols => [
            'user_id',               # becomes "User ID" aligned right due to data
            [ 'thing', 'Things' ],   # becomes "Things" aligned left
            [ 'stuff_things', 'r' ], # becomes "Stuff Things" aligned right explicitly
            [ 'x', 'c', 'Name' ],    # becomes "Name" aligned center explicitly
        ],
    );
    # | User ID | Things   | Stuff Things | Name |
    # |--------:|----------|-------------:|:----:|
    # |    1138 | Thing 1  |        Stuff | 2048 |
    # |    1024 | Thing 16 |       Things |  16  |

=head1 DESCRIPTION

This package provides exportable utility functions for tables.

=head1 FUNCTION

=head2 table

This function returns a string representation of a table suitable for
command-line printing. By default, the string will be in Markdown table format.

At minimum, it requires table data in the form of an array of arrays or hashes.

    say table( [ [ 1, 2, 3 ], [ 4, 5, 6 ] ] );
    # | 1 | 2 | 3 |
    # | 4 | 5 | 6 |

If hashes are used, the hash keys will become the column headers after some
transformation: underscores will become spaces and words will be capitalized.

    say table( [
        { alpha => 1, bravo => 2, charlie_delta => 'Stuff and Things' },
        { alpha => 4, bravo => 5, charlie_delta => 'Things and Stuff and More' },
    ] );
    # | Alpha | Bravo | Charlie Delta             |
    # |------:|------:|---------------------------|
    # |     1 |     2 | Stuff and Things          |
    # |     4 |     5 | Things and Stuff and More |

By labeling the row data with the C<rows> key, you can provide additional keys
to alter the output. The C<cols> value if provided is an array of columns to
pull from the hashes of the C<rows> array.

    say table(
        rows => [
            { thing => 'Thing 1',  x => 2048, stuff_things => 'Stuff',  user_id => 1138 },
            { thing => 'Thing 16', x =>   16, stuff_things => 'Things', user_id => 1024 },
        ],
        cols => [
            'user_id',               # becomes "User ID" aligned right due to data
            [ 'thing', 'Things' ],   # becomes "Things" aligned left
            [ 'stuff_things', 'r' ], # becomes "Stuff Things" aligned right explicitly
            [ 'x', 'c', 'Name' ],    # becomes "Name" aligned center explicitly
        ],
    );
    # | User ID | Things   | Stuff Things | Name |
    # |--------:|----------|-------------:|:----:|
    # |    1138 | Thing 1  |        Stuff | 2048 |
    # |    1024 | Thing 16 |       Things |  16  |

You can optionally add an C<acronyms> array of words that if found during column
name formatting will cause the word to be represented in all upper case. By
default, "ID" is the only acronym set.

You can also optionally add a C<style>. If no style is set, the output is in
Markdown table format. The 3 supported styles are: C<classic>, C<boxrule>, and
C<norule>.
