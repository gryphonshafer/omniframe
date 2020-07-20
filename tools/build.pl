#!/usr/bin/env perl
use exact -cli, -conf;
use File::Copy 'cp';
use Mojo::File 'path';
use YAML::XS 'DumpFile';

my $opt = options( qw{ name|n=s dir|d=s } );

$opt->{name} //= 'Project';
$opt->{dir}  //= '.';

my $root_dir = conf->get( qw( config_app root_dir ) );
my $proj_dir = path( $opt->{dir} )->to_rel->to_string;

path( $proj_dir . '/' . $_ )->make_path for (
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

$config->{preinclude}            = path( $root_dir . '/config/app.yaml', $opt->{dir} )->to_rel->to_string;
$config->{default}{omniframe}    = path( $root_dir,                      $opt->{dir} )->to_rel->to_string;
$config->{default}{libs}         = path( $root_dir . '/lib',             $opt->{dir} )->to_rel->to_string;
$config->{default}{mojo_app_lib} = "$opt->{name}::Control";

$config->{default}{mojolicious}{secrets} = [
    substr( join( '', map { crypt( rand() * 10**15, rand() * 10**15 ) } 0 .. 2 ), 0, 32 )
];

$config->{default}{mojolicious}{session}{cookie_name} = lc( $opt->{name} ) . '_session';

local $YAML::XS::Indent = 4;
DumpFile( $proj_dir . '/config/app.yaml', $config );

path( $root_dir . '/lib/Project' )
    ->list_tree({ hidden => 1 })
    ->each( sub {
        my $src = $_->to_string;
        ( my $dest = $src ) =~ s!^$root_dir/lib/Project!$proj_dir/lib/$opt->{name}!;

        my $file = path($dest);
        $file->dirname->make_path;

        cp( $src, $dest );

        ( my $content = $file->slurp ) =~ s/\bProject::/$opt->{name}::/g;
        $file->spurt($content);
    } );

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
