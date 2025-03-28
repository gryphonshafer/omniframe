#!/usr/bin/env perl
use Cwd 'cwd';
use FindBin;
BEGIN { $FindBin::Bin = cwd(); }

use exact -cli, -conf;
use DDP;
use Mojo::File 'path';
use Mojo::Util 'decode';
use Mojo::JSON qw( to_json from_json );
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
my $where = from_json( $opt->{where} );
$where    = { $opt->{table} . '_id' => $where } unless ( ref $where );

my ( $yaml, $data, $json );

if ( $opt->{import} ) {
    $data = Load( encode( 'UTF-8', path( $opt->{import} )->slurp('UTF-8') ) );
    $yaml = decode( 'UTF-8', Dump($data) );
    $json = to_json($data);

    $dq->update(
        $opt->{table},
        { $opt->{field} => $json },
        $where,
    );
}
else {
    $json = $dq->get( $opt->{table}, [ $opt->{field} ], $where, { rows => 1 } )->run->value;
    $data = from_json($json);
    $yaml = decode( 'UTF-8', Dump($data) );
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
        -i,     --import   IMPORT_YAML_FILE
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

YAML file to import from.

=head2 -o, --output

Output format. Can be: DDP, JSON, or YAML.
