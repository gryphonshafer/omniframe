#!/usr/bin/env perl
use Cwd 'cwd';
use FindBin;
BEGIN { $FindBin::Bin = cwd(); }

use exact -cli, -conf;
use Omniframe;
use YAML::XS qw( Load Dump );
use Mojo::JSON qw( encode_json decode_json );
use Mojo::File 'path';

my $opt = options( qw{
    database|d=s
    table|t=s
    field|f=s
    where|w=s
    import|i=s
} );

pod2usage('Must specify table, field, where')
    unless ( $opt->{table} and $opt->{field} and $opt->{where} );

my $dq    = Omniframe->with_roles('+Database')->new->dq( $opt->{database} );
my $where = decode_json( $opt->{where} );
$where    = { $opt->{table} . '_id' => $where } unless ( ref $where );

if ( $opt->{import} ) {
    my $json = encode_json( Load( path( $opt->{import} )->slurp ) );

    $dq->update(
        $opt->{table},
        { $opt->{field} => $json },
        $where,
    );

    say $json;
}
else {
    my @values =
        map { decode_json($_) }
        $dq->get( $opt->{table}, [ $opt->{field} ], $where )->run->value;

    say Dump( ( @values > 1 ) ? \@values : $values[0] );
}

=head1 NAME

yaml_json.pl - Export/import JSON as YAML to/from database

=head1 SYNOPSIS

    yaml_json.pl OPTIONS
        -d, --database DATABASE_LABEL
        -t, --table    TABLE_NAME
        -f, --field    FIELD_NAME
        -w, --where    PID_OR_WHERE_CLAUSE_AS_JSON
        -e, --export, -x
        -i, --import
        -h, --help
        -m, --man

=head1 DESCRIPTION

This program will export or import JSON as YAML to or from a database.

=head2 -d, --database

Optionally specify database name.

=head2 -t, --table

Table name to select from or update to.

=head2 -f, --field

Field name (containing JSON) to select from or update to.

=head2 -w, --where

Primary key ID or a SQL where clause expressed as JSON.

=head2 -e, --export

Export to YAML file.

=head2 -i, --import

Export import from YAML file.
