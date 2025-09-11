package Omniframe::Util::Data;

use exact -conf;
use Mojo::JSON 'from_json';
use Mojo::File 'path';
use YAML::XS qw( LoadFile Load Dump );

exact->exportable( qw( dataload deepcopy node_descend ) );

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

sub node_descend ( $top_node, @hooks ) {
    my $hooks;
    for (@hooks) {
        my ( $when, $type, $code ) = @$_;
        $hooks->{ uc $type }{$when} = $code if ( ref $code eq 'CODE' );
    }

    my $descend_node;
    $descend_node = sub ($node) {
        my $ref = ref $node;

        my $process_node = sub ($callback) {
            if ( $hooks->{$ref} and $hooks->{$ref}{wrap} ) {
                $hooks->{$ref}{wrap}->( $node, $callback );
            }
            else {
                $hooks->{$ref}{pre}->($node) if ( $hooks->{$ref} and $hooks->{$ref}{pre} );
                $callback->();
                $hooks->{$ref}{post}->($node) if ( $hooks->{$ref} and $hooks->{$ref}{post} );
            }
        };

        if ( $ref eq 'ARRAY' or $ref eq 'HASH' ) {
            $process_node->(
                ( $ref eq 'ARRAY' ) ? sub { $descend_node->($_)            for (@$node)        } :
                ( $ref eq 'HASH'  ) ? sub { $descend_node->( $node->{$_} ) for ( keys %$node ) } : sub {}
            );
        }
        else {
            $hooks->{$ref}{pre} ->($node) if ( $hooks->{$ref} and $hooks->{$ref}{pre} );
            $hooks->{$ref}{post}->($node) if ( $hooks->{$ref} and $hooks->{$ref}{post} );
        }
    };
    $descend_node->($top_node);

    return $top_node;
}

1;

=head1 NAME

Omniframe::Util::Data

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::Data qw( dataload deepcopy node_descend );

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

=head2 node_descend

Given a data structure, descend its nodes, running callbacks based on the type
of sub-node data encountered. For example:

    node_descend(
        [ { thx => 1138 }, { answer => 42 }, { combination => 12345 } ],
        [ 'post', 'hash', sub ($node) { $node->{touched} = 1 } ],
    );

In this example, the first arrayref is the data structure to descend. All
subsequent inputs should be arrayrefs containing 3 items: a "pre" or "post"
designation, a reference type (case-insensitive), and a callback. So in this
example, after ("post") any hash, the callback is executed on the current node.

On may also use a designation of "wrap", which expects the callback you provide
to receive and call a callback internally:

    node_descend(
        [ { thx => 1138 }, { answer => 42 } ],
        [ 'wrap', 'hash', sub ( $node, $callback ) {
            $node->{touched} = 1;
            $callback->();
        } ],
    );

In all cases, this function will return the top-most node of the data structure
passed into it.
