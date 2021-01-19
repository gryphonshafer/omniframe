#!/usr/bin/env perl
use Cwd 'cwd';
use FindBin;
BEGIN { $FindBin::Bin = cwd(); }

use exact -cli, -conf;
use Omniframe::Util::Sass;
use Omniframe::Util::Watch;

my $opt  = options( qw{ production|p watch|w } );
my $sass = Omniframe::Util::Sass->new;

$sass->mode('production') if ( $opt->{production} );

my $report = sub {
    printf "[%s] [%s] %s\n",
        scalar(localtime),
        ( $opt->{production} ) ? 'prod' : 'dev',
        $sass->compile_to;
};

$sass->build;
$report->();

Omniframe::Util::Watch->new->watch(
    sub {
        $sass->build(
            $report,
            sub ($error) { warn $error . "\n" },
        )
    },
    $sass->scss_src,
) if ( $opt->{watch} );

=head1 NAME

sass.pl - Build CSS file from SASS assets

=head1 SYNOPSIS

    sass.pl OPTIONS
        -p, --production  # set mode to production versus development default
        -w, --watch       # run in "watch" mode
        -h, --help
        -m, --man

=head1 DESCRIPTION

This program will build CSS file from SASS assets.

=head1 OPTIONS

=head2 -p, --production

Set mode to production versus development default.

=head2 -w, --watch

Run in "watch" mode.
