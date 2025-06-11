#!/usr/bin/env perl
use exact -cli, -conf;
use File::Copy 'cp';
use File::Copy::Recursive 'dircopy';
use Mojo::File 'path';
use Omniframe::Util::Crypt 'urand';
use YAML::XS 'DumpFile';

my $opt = options( qw{ name|n=s dir|d=s } );

$opt->{name} //= 'Project';
$opt->{dir}  //= '.';

$opt->{name} = ucfirst $opt->{name};

my $root_dir = conf->get( qw( config_app root_dir ) );
my $proj_dir = path( $opt->{dir} )->to_rel->to_string;

dircopy(
    $root_dir . '/' . $_,
    $proj_dir . '/' . $_,
) for ( qw(
    config/db
    t/kwalitee
) );

cp(
    $root_dir . '/' . $_,
    $proj_dir . '/' . $_,
) for ( qw(
    app.psgi
    dest.watch
    .gitignore
    static/security.txt
) );

path( $proj_dir . '/t/app' )->make_path;
( my $content = path( $root_dir . '/t/app/home_page.t' )->slurp('UTF-8') ) =~ s/\bProject::/$opt->{name}::/g;
path( $proj_dir . '/t/app/home_page.t' )->spew( $content, 'UTF-8' );

local $YAML::XS::Indent = 4;

DumpFile( $proj_dir . '/config/app.yaml', {
    preinclude => path( $root_dir . '/config/app.yaml', $opt->{dir} )->to_rel->to_string,
    default    => {
        omniframe    => path( $root_dir,          $opt->{dir} )->to_rel->to_string,
        libs         => path( $root_dir . '/lib', $opt->{dir} )->to_rel->to_string,
        mojo_app_lib => "$opt->{name}::Control",
        mojolicious  => {
            secrets => [
                substr( join( '', map { crypt( urand() * 10**15, urand() * 10**15 ) } 0 .. 2 ), 0, 32 ),
            ],
            session => {
                cookie_name => lc( $opt->{name} ) . '_session',
            },
        },
        bcrypt => {
            salt => substr( join( '', map { crypt( urand() * 10**15, urand() * 10**15 ) } 0 .. 2 ), 0, 16 ),
        },
    },
    optional_include => 'local/config.yaml',
} );
say $proj_dir . '/config/app.yaml';

path( $proj_dir . '/local' )->make_path;
DumpFile( $proj_dir . '/local/config.yaml', {
    default    => {
        mojolicious  => {
            secrets => [
                substr( join( '', map { crypt( urand() * 10**15, urand() * 10**15 ) } 0 .. 2 ), 0, 32 ),
            ],
        },
        bcrypt => {
            salt => substr( join( '', map { crypt( urand() * 10**15, urand() * 10**15 ) } 0 .. 2 ), 0, 16 ),
        },
    },
} );
say $proj_dir . '/local/config.yaml';

for my $type (
    [ 'lib',    '/lib/Project'    ],
    [ 't/unit', '/t/unit/Project' ],
) {
    path( $root_dir . $type->[1] )
        ->list_tree({ hidden => 1 })
        ->each( sub {
            my $src = $_->to_string;
            ( my $dest = $src ) =~ s!^$root_dir/$type->[0]/Project!$proj_dir/$type->[0]/$opt->{name}!;

            my $file = path($dest);
            $file->dirname->make_path;

            cp( $src, $dest );

            ( my $content = $file->slurp('UTF-8') ) =~ s/\bProject::/$opt->{name}::/g;
            $file->spew( $content, 'UTF-8' );

            say $dest;
        } );
}

=head1 NAME

build_app.pl - Build an application subframework based on Omniframe

=head1 SYNOPSIS

    build_app.pl OPTIONS
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
