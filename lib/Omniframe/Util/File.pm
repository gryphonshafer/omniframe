package Omniframe::Util::File;

use exact -conf;
use Mojo::File;

exact->exportable('opath');

sub opath (@parts) {
    my ($settings) = grep { ref $_ eq 'HASH' } @parts;
    $settings //= {};
    my $file = join( '/', grep { defined and not ref $_ } @parts );

    $settings->{paths} //= [ grep { defined }
        conf->get( qw( config_app root_dir ) ),
        ( conf->get('omniframe') )
            ? conf->get( qw( config_app root_dir ) ) . '/' . conf->get('omniframe')
            : undef,
    ];

    $settings->{paths} = [ reverse @{ $settings->{paths} } ]
        if ( $settings->{omniframe} and not $settings->{paths} );

    for my $path (
        grep { $_ } map { glob( $_ . '/' . $file ) } $settings->{paths}->@*
    ) {
        return Mojo::File->new($path)
            if ( $settings->{no_check} or -f $path and -r $path );
    }

    croak qq{File does not exist or is not readable: "$file"};
}

1;

=head1 NAME

Omniframe::Util::File

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::File 'opath';

    my $css = opath('static/build/app.css')->slurp('UTF-8');

=head1 DESCRIPTION

This package provides exportable utility function C<opath> that acts somewhat
like C<path> from L<Mojo::File>.

=head1 FUNCTIONS

=head2 opath

This function acts like somewhat like the C<path> function from L<Mojo::File>,
but behind the scenes, it does some L<Omniframe>-specific work by default.

    my $css_0 = opath('static/build/app.css')->slurp('UTF-8');
    my $css_1 = opath( qw( static build app.css ) )->slurp('UTF-8');

Globs are supported. If multiple files are matched, only the first (that's
readable, unless C<no_check> is set) is used:

    my $css_2 = opath('static/*/app.css')->slurp('UTF-8');

It will first check for the file to exist and be readable relative to the
project's root directory. If it doesn't find the file there, it will look under
the L<Omniframe> root directory. And if the file still isn't found, it will
throw an error.

The behavior can be modified by providing a settings hashref.

    my $icon = opath(
        qw( static favicon.ico ),
        { no_check => 1 },
    )->slurp('UTF-8');

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
