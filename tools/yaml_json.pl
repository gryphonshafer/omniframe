#!/usr/bin/env perl
use Cwd 'cwd';
use FindBin;
BEGIN { $FindBin::Bin = cwd(); }

use exact -cli, -conf;
use DDP;
use Mojo::File 'path';
use Mojo::JSON qw( encode_json decode_json );
use YAML::XS qw( Load Dump );
use Omniframe;

my $opt = options( qw{
    database|d=s
    table|t=s
    field|f=s
    where|w=s
    import|i=s
    output|o=s
} );

pod2usage('Must specify table, field, where')
    unless ( $opt->{table} and $opt->{field} and $opt->{where} );

my $dq    = Omniframe->with_roles('+Database')->new->dq( $opt->{database} );
my $where = decode_json( $opt->{where} );
$where    = { $opt->{table} . '_id' => $where } unless ( ref $where );

my ( $yaml, $data, $json );

if ( $opt->{import} ) {
    $data = Load( path( $opt->{import} )->slurp );
    $yaml = Dump($data);
    $json = encode_json($data);

    $dq->update(
        $opt->{table},
        { $opt->{field} => $json },
        $where,
    );
}
else {
    $json = $dq->get( $opt->{table}, [ $opt->{field} ], $where, { rows => 1 } )->run->value;
    $data = decode_json($json);
    $yaml = Dump($data);
}

if ( ( $opt->{output} // '' ) =~ /^d/i ) {
    p $data;
}
elsif ( ( $opt->{output} // '' ) =~ /^j/i ) {
    say $json;
}
elsif ( ( $opt->{output} // '' ) =~ /^y/i ) {
    say $yaml;
}

=head1 NAME

yaml_json.pl - Export/import JSON as YAML to/from database

=head1 SYNOPSIS

    yaml_json.pl OPTIONS
        -d,     --database DATABASE_LABEL
        -t,     --table    TABLE_NAME
        -f,     --field    FIELD_NAME
        -w,     --where    PID_OR_WHERE_CLAUSE_AS_JSON
        -i,     --import
        -o,     --output   OUTPUT_TYPE
        -h,     --help
        -m,     --man

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

=head2 -i, --import

Export import from YAML file.

=head2 -o, --output

Output format. Can be: DDP, JSON, or YAML.
