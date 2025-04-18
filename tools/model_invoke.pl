#!/usr/bin/env perl
use Cwd 'cwd';
use FindBin;
BEGIN { $FindBin::Bin = cwd(); }

use exact -cli, -conf;
use Data::Printer;
use Mojo::JSON 'to_json';
use Mojo::Util 'camelize';
use YAML::XS 'Dump';

my $opt = options(
    'model|m=s',
    'action|a=s',
    'id|i=s',
    'hash|h=s{,}',
    'params|p=s{,}',
    'namespace|n=s',
    'silent|s',
    'verbose|v',
    'output|o=s',
);

( $opt->{namespace} = conf->get('mojo_app_lib') ) =~ s/::Control// unless ( $opt->{namespace} );
pod2usage('Must provide at least a model and action') unless ( $opt->{model} and $opt->{action} );

sub use_class ($name) {
    my $class = camelize( $opt->{namespace} ) . '::Model::' . camelize($name);
    eval "require $class" or die $@;
    return $class;
}

my $obj = use_class( $opt->{model} )->new;
$obj->load( $opt->{id} ) if ( $opt->{id} );

for my $element ( @{ $opt->{params} || [] }, @{ $opt->{hash} || [] } ) {
    if ( $element =~ /^\\(?<class>[\w:\-]+):(?<id>\d+)$/ ) {
        $element = use_class( $+{class} )->new->load( $+{id} );
    }
}

my $action = $opt->{action};
my $rv;
try {
    $rv = $obj->$action(
        grep { defined }
            ( ( $opt->{hash} ) ? { @{ $opt->{hash} } } : undef ),
            @{ $opt->{params} || [] }
    );
}
catch ($e) {
    die '', ( $opt->{verbose} ) ? $e : ( deat $e, "\n" );
}

unless ( $opt->{silent} ) {
    $opt->{output} //= 'data';
    if ( uc $opt->{output} eq 'YAML' ) {
        say decode( 'UTF-8', Dump($rv) );
    }
    elsif ( uc $opt->{output} eq 'JSON' ) {
        say to_json($rv);
    }
    else {
        say np( $rv, colored => 1 );
    }
}

=head1 NAME

model_invoke.pl - Invoke model methods

=head1 SYNOPSIS

    model_invoke.pl OPTIONS
        -m, --model     MODEL_CLASS_NAME_SUFFIX
        -a, --action    METHOD_NAME
        -i, --id        DATABASE_PK_ID
        -h, --hash      NAME VALUE DATA PAIRS
        -p, --params    LIST OF PARAMS
        -n, --namespace MODEL_CLASS_NAMESPACE
        -s, --silent
        -v, --verbose
        -o, --output    OUTPUT_TYPE # "data" (default), "YAML", or "JSON"
        -h, --help
        -m, --man

=head1 DESCRIPTION

This program provides a means of simple invokation of model methods. It must be
provided with a model class name suffix and a method to run from that class
along with either a hash or parameters to pass.

    ./model_invoke.pl -m class_name_suffix -a method -h key value key2 value2
    ./model_invoke.pl -m class_name_suffix -a method -p alpha beta delta gamma
    ./model_invoke.pl -m class_name_suffix -a method -p '\other_class:42'

=head1 OPTIONS

=head2 -m, --model

A model class name suffix is something like "user" or "special_thing" which will
be used as Project::Model::User and Project::Model::SpecialThing respectively.

=head2 -a, --action

An action is the name of the subroutine of the class of the model.

=head2 -i, --id

If you need to load a specific database record by PK ID, this is how you can
optionally provide that data.

=head2 -h, --hash

If the method requires a hashref be provided as input, you can specify that data
with the hash flag. It assumes input provided after it and prior to any other
flags are key/value pairs of the hash.

    ./model_invoke.pl -m class_name_suffix -a method -h key value key2 value2

=head2 -p, --params

If the method requires a series of parameters as input, you can specify that
data with the params flag.

    ./model_invoke.pl -m class_name_suffix -a method -p alpha beta delta gamma

=head2 -n, --namespace

By default, whatever is found set in as the "mojo_app_lib" value in the
application's configuration will be used as the basis to determine the model's
namespace. However, you can explicitly set it.

    ./model_invoke.pl -n Project::Model -m class_name_suffix -a method

=head2 -s, --silent

Don't print any output. (Will still display errors if any.)

=head2 -v, --verbose

If there any errors, these will be printed with a line number (whereas otherwise
by default the line numbers are surpressed).

=head2 -o, --output

Specify output type. Defaults to "data" which is data printing. Other options
are "YAML" and "JSON".

=head1 OBJECTS

If a method requires as input a particular instantiated object loaded with
database record data, you can accomplish this by providing the model class name
suffix prefaced with a backslash and followed by a colon and the PK ID.

    ./model_invoke.pl -m class_name_suffix -a method -p '\other_class:42'
