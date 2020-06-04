#!/usr/bin/env perl
use exact -cli, -conf;
use File::Copy 'cp';
use File::Find 'find';
use File::Path 'make_path';
use File::Spec;
use Mojo::File;
use YAML::XS 'DumpFile';

my $opt = options( qw{ name|n=s dir|d=s } );

$opt->{name} //= 'Project';
$opt->{dir}  //= '.';

my $root_dir = conf->get( qw( config_app root_dir ) );
my $proj_dir = File::Spec->rel2abs( $opt->{dir} );

make_path( $proj_dir . '/' . $_ ) for (
    'config/db',
    'lib/' . $opt->{name},
);

cp(
    $root_dir . '/' . $_,
    $proj_dir . '/' . $_,
) for ( qw(
    config/db/dest.wrap
    app.psgi
    dest.watch
    .gitignore
) );

my $config = {};

$config->{preinclude}            = File::Spec->abs2rel( $root_dir . '/config/app.yaml', $opt->{dir} );
$config->{default}{omniframe}    = File::Spec->abs2rel( $root_dir, $opt->{dir} );
$config->{default}{libs}         = File::Spec->abs2rel( $root_dir . '/lib', $opt->{dir} );
$config->{default}{mojo_app_lib} = "$opt->{name}::Control";

$config->{default}{mojolicious}{secrets} = [
    substr( join( '', map { crypt( rand() * 10**15, rand() * 10**15 ) } 0 .. 2 ), 0, 32 )
];

$config->{default}{mojolicious}{session}{cookie_name} = lc( $opt->{name} ) . '_session';

local $YAML::XS::Indent = 4;
DumpFile( $proj_dir . '/config/app.yaml', $config );

find(
    sub {
        my $src = $File::Find::name;
        ( my $dest = $src ) =~ s!^$root_dir/lib/Project!$proj_dir/lib/$opt->{name}!;

        if ( $_ eq '.' ) {
            make_path($dest);
        }
        else {
            cp( $src, $dest );

            my $file = Mojo::File->new($dest);
            ( my $content = $file->slurp ) =~ s/\bProject::/$opt->{name}::/g;
            $file->spurt($content);
        }
    },
    $root_dir . '/lib/Project',
);

=head1 NAME

build.pl - Build an application subframework based on Omniframe

=head1 SYNOPSIS

    build.pl OPTIONS
        -n, --name NAME  # project's name (default: "Project")
        -d, --dir  DIR   # project's root directory (default: ".")
        -h, --help
        -m, --man

=head1 DESCRIPTION

This program will build an application subframework based on Omniframe.

=head1 OPTIONS

=head2 -n, --name

This is the project's name in CamelCase. It defaults to "Project" if not set.

=head2 -d, --directory

This is the new project's root directory. If not defined, it defaults to "."
or the current directory. If it doesn't exist, this directory will be created.
