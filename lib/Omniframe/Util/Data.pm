package Omniframe::Util::Data;

use exact -conf;
use Mojo::JSON 'from_json';
use Mojo::File 'path';
use YAML::XS qw( LoadFile Load Dump );

exact->exportable( qw( dataload deepcopy ) );

sub dataload ($file) {
    my $path = path( conf->get( qw( config_app root_dir ) ) . '/' . $file );
    return
        ( $file =~ /\.yaml$/i ) ? LoadFile($path) :
        ( $file =~ /\.json$/i )
            ? from_json( $path->slurp('UTF-8') )
            : $path->slurp('UTF-8');
}

sub deepcopy (@items) {
    return unless (@items);
    my @results = map { Load( Dump($_) ) } @items;
    return ( @results == 1 ) ? $results[0] : ( wantarray ) ? @results : \@results;
}

1;

=head1 NAME

Omniframe::Util::Data

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::Data qw( dataload deepcopy );

    my $decoded_data = dataload('relative/path/data.yaml');

    my $deep_copy   = deepcopy($decoded_data);
    my $deep_copies = deepcopy( $decoded_data, $decoded_data );
    my @deep_copies = deepcopy( $decoded_data, $decoded_data );

=head1 DESCRIPTION

This package provides exportable utility functions for data.

=head1 FUNCTIONS

=head2 dataload

This method will load a YAML or JSON file from within the project's directory
tree based on the realtive path to the file from the projects's root directory.
The method will return the data from the source file.

    my $decoded_data = dataload('relative/path/data.yaml');

=head2 deepcopy

This method expects any number of data objects as input and will create "deep
copies" of them, meaning any internal references will be replicated instead of
maintained, allowing for alteration of said reference content without infecting
the original data objects.

    my $deep_copy = deepcopy($decoded_data);

If multiple inputs are provided, the context of the call will cause either an
array or arrayref to be returned.

    my $deep_copies = deepcopy( $decoded_data, $decoded_data );
    my @deep_copies = deepcopy( $decoded_data, $decoded_data );
