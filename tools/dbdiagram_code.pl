#!/usr/bin/env perl
use Cwd 'cwd';
use DBIx::Query;
use FindBin;
BEGIN { $FindBin::Bin = cwd(); }

use exact -cli, -conf;

my $opt = options('database|d=s');
pod2usage('Must provide readable database file') unless ( -r ( $opt->{database} || '' ) );

my $dq = DBIx::Query->connect( 'dbi:SQLite:dbname=' . $opt->{database} );

my ( @tables, @refs );
for my $sql ( map { $_->[0] } @{ $dq->sql(q{
    SELECT sql FROM sqlite_master WHERE type = ? AND name NOT LIKE "sqlite_%"
})->run('table')->all } ) {
    $sql =~ s/\s+/ /g;
    $sql =~ /^\s*CREATE\s+TABLE\s+(\w+)\s*\(\s*(.*?)\s*\)\s*$/;

    my ( $table, $cols ) = ( $1, $2 );
    1 while ( $cols =~ s/(\([^\),]*),/$1;/ );

    my @cols;
    for ( map { s/;/,/r } split( /\s*,\s*/, $cols ) ) {
        if ( /^\bFOREIGN KEY \(([^\)]+)\) REFERENCES (\w+)\(([^\)]+)\)/i ) {
            push( @refs, 'ref { ' . $table . '.' . $1 . ' > ' . $2 . '.' . $3 . ' }' );
        }
        elsif ( not /^\b(?:UNIQUE|CHECK|CONSTRAINT)\b/i ) {
            /(\w+)\s(\w+)/;
            my $col = $1 . ' ' . lc($2);

            my @suffix;

            push( @suffix, 'pk'           ) if ( /\bPRIMARY KEY\b/i    );
            push( @suffix, 'increment'    ) if ( /\bAUTOINCREMENT\b/i  );
            push( @suffix, 'unique'       ) if ( /\bUNIQUE\b/i         );
            push( @suffix, "default:`$1`" ) if ( /\bDEFAULT\b\s*(.+)/i );

            if ( /\bNOT NULL\b/i ) {
                push( @suffix, 'not null' );
            }
            elsif ( /\bNULL\b/i ) {
                push( @suffix, 'null' ) if ( /\bNULL\b/i );
            }

            $col .= ' [' . join( ', ', @suffix ) . ']' if ( @suffix > 0 );

            push( @cols, $col );
        }
    }

    push( @tables, {
        name => $table,
        cols => \@cols,
    } )
}

for my $table (@tables) {
    say "table $table->{name} {";
    say ' ' x 4 . $_ for ( @{ $table->{cols} } );
    say "}\n";
}
say join( "\n", @refs );

=head1 NAME

dbdiagram_code.pl - Build dbdiagram.io schema code from database schema

=head1 SYNOPSIS

    dbdiagram_code.pl OPTIONS
        -d, --database SQLITE3_DATABASE_FILE
        -h, --help
        -m, --man

=head1 DESCRIPTION

This program will build dbdiagram.io schema code by reading a SQLite3 database
file and investigating its schema.

=head1 OPTIONS

=head2 -d, --database

The SQLite3 database file.
