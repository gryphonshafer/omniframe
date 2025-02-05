package Omniframe::Util::File;

use exact -conf;
use Mojo::File;

exact->exportable('path');

sub path (@parts) {
    my ($settings) = grep { ref $_ eq 'HASH' } @parts;
    $settings //= {};
    my $file = join( '/', grep { not ref $_ } @parts );

    $settings->{paths} //= [ grep { defined }
        conf->get( qw( config_app root_dir ) ),
        ( conf->get('omniframe') )
            ? conf->get( qw( config_app root_dir ) ) . '/' . conf->get('omniframe')
            : undef,
    ];

    $settings->{paths} = [ reverse @{ $settings->{paths} } ]
        if ( $settings->{omniframe} and not $settings->{paths} );

    for my $path ( map { $_ . '/' . $file } $settings->{paths}->@* ) {
        return Mojo::File->new($path) if ( $settings->{no_check} or -r $path );
    }

    croak "File does not exist or is not readable: $file";
}

1;

=head1 NAME

Omniframe::Util::File

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::File 'path';

    my $css = path('static/build/app.css')->slurp;

=head1 DESCRIPTION

This package provides exportable utility function C<path> that acts somewhat
like C<path> from L<Mojo::File>.

=head1 FUNCTIONS

=head2 path

This function acts like somewhat like the C<path> function from L<Mojo::File>,
but behind the scenes, it does some L<Omniframe>-specific work by default.

    my $css_0 = path('static/build/app.css')->slurp;
    my $css_1 = path( qw( static build app.css ) )->slurp;

It will first check for the file to exist and be readable relative to the
project's root directory. If it doesn't find the file there, it will look under
the L<Omniframe> root directory. And if the file still isn't found, it will
throw an error.

The behavior can be modified by providing a settings hashref.

    my $icon = path( qw( static favicon.ico ), { no_check => 1 } )->slurp;

These are the supported keys:

=head3 omniframe

If set to a true value, the L<Omniframe> root directory is checked before the
project's root directory.

=head3 no_check

If set to a true value, the existance and readability checks are skipped. This
necessarily means that whatever root directory is first will be what's used.

=head3 paths

If set to an arrayref with paths, this will explicitly sets the path or paths
searched, in order. If C<paths> is set, then the C<omniframe> value is ignored.
