#!/usr/bin/env perl
use Cwd 'cwd';
use FindBin;
BEGIN { $FindBin::Bin = cwd(); }

use exact -cli, -conf;
use Omniframe::Class::Sass;
use Omniframe::Class::Watch;

my $opt  = options( qw{ production|p watch|w } );
my $sass = Omniframe::Class::Sass->new;

$sass->mode('production') if ( $opt->{production} );

my $report = sub {
    printf "[%s] [%s] %s\n",
        scalar(localtime),
        ( $opt->{production} ) ? 'prod' : 'dev',
        $sass->compile_to;
};

$sass->build;
$report->();

Omniframe::Class::Watch->new->watch(
    sub {
        $sass->build(
            $report,
            sub ($error) { warn $error . "\n" },
        )
    },
    $sass->scss_src,
) if ( $opt->{watch} );

=head1 NAME

sass_compile.pl - Compile CSS file from SASS assets

=head1 SYNOPSIS

    sass_compile.pl OPTIONS
        -p, --production  # set mode to production versus development default
        -w, --watch       # run in "watch" mode
        -h, --help
        -m, --man

=head1 DESCRIPTION

This program will compile a CSS file from SASS assets.

=head1 OPTIONS

=head2 -p, --production

Set mode to production versus development default.

=head2 -w, --watch

Run in "watch" mode.
