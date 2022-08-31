#!/usr/bin/env perl
use exact -cli, -conf;
use Mojo::File 'path';
use Mojo::UserAgent;
use YAML::XS 'LoadFile';

my $opt = options( qw{ settings|s=s dir|d=s } );

$opt->{settings} //= q{config/externals.yaml};
$opt->{dir}      //= q{.};

my $omni_path = path( conf->get( qw( config_app root_dir ) ) );
my $proj_path = path( $opt->{dir} );
my $ext_yaml  = LoadFile( $proj_path->child( $opt->{settings} )->to_string );
my $ua        = Mojo::UserAgent->new( max_redirects => 3 );

if ( $ext_yaml->{google_fonts} ) {
    my $dest_fonts = $omni_path->child( $ext_yaml->{google_fonts}{dest}{fonts} );
    my $dest_css   = $omni_path->child( $ext_yaml->{google_fonts}{dest}{css}   );

    $dest_css->make_path;

    while ( my ( $font_name, $font_set ) = each %{ $ext_yaml->{google_fonts}{fonts} } ) {
        my $font_key = lc $font_name;
        $font_key =~ s/\s+/\-/g;

        my $save_to = $dest_fonts->child( $font_key . '/download.zip' );
        $save_to->dirname->make_path;

        $ua->get(
            'https://google-webfonts-helper.herokuapp.com/api/fonts/' . $font_key,
            form => {
                download => 'zip',
                map {
                    $_ => join( ',',
                        ( ref $font_set->{$_} eq 'HASH' )
                            ? values %{ $font_set->{$_} }
                            : @{ $font_set->{$_} }
                    )
                } keys %$font_set
            },
        )->result->save_to( $save_to->to_string );

        system( 'cd ' . $save_to->to_abs->dirname . '; unzip -a -o -qq download.zip' );
        unlink( $save_to->to_string );

        my ($version) = substr(
            $save_to->to_abs->dirname->list->first->basename,
            length $font_key,
        ) =~ /\-(v\d+)/;

        my @font_face_css_blocks;

        for ( map { [ $_, $font_set->{variants}{$_} ] } sort keys %{ $font_set->{variants} } ) {
            my ( $font_family, $variant ) = @$_;

            push(
                @font_face_css_blocks,
                join(
                    "\n",
                    q\@font-face {\,
                    qq\    font-family : '$font_family';\,
                    qq\    src         : local('$font_family'),\,
                    join( ",\n", map {
                        sprintf(
                            ' ' x 18 . q\url('fonts/%s/%s-%s-%s-%s.%s') format('%s')\,
                            $font_key,
                            $font_key,
                            $version,
                            join( '-', @{ $font_set->{subsets} } ),
                            $variant,
                            $_,
                            (
                                ( $_ eq 'eot' ) ? 'embedded-opentype' :
                                ( $_ eq 'ttf' ) ? 'truetype'          : $_
                            ),
                        )
                    } @{ $font_set->{formats} } ) . ';',
                    q\}\,
                ),
            );
        }

        $dest_css->child( $font_key . '.css' )->spurt(
            join( "\n\n", @font_face_css_blocks ) . "\n"
        );
    }

    if ( my $icons = $ext_yaml->{google_fonts}{icons} ) {
        $ua->transactor->name( $icons->{browser} );
        my $save_to = $dest_fonts->child('material-icons')->make_path;
        my ( @font_face_css_blocks, @font_style_css_blocks );

        for my $icon_name ( @{ $icons->{types} } ) {
            my ($icon_url) = $ua->get(
                'https://fonts.googleapis.com/icon', form => { family => $icon_name },
            )->result->body =~ /src:\s*url\(([^\)]+)\)/;

            my ($version) = $icon_url =~ m|/(v\d+)/|;
            my ($format)  = $icon_url =~ /\.(\w+)$/;
            ( my $icon_key = lc $icon_name ) =~ s/\s+/\-/g;

            $ua->get($icon_url)->result->save_to(
                $save_to->child( $icon_key . '-' . $version . '.' . $format )->to_string
            );

            push(
                @font_face_css_blocks,
                join(
                    "\n",
                    q\@font-face {\,
                    qq\    font-family : '$icon_name';\,
                    q\    font-style  : normal;\,
                    q\    font-weight : 400;\,
                    qq\    src         : local('$icon_name'),\,
                    sprintf(
                        ' ' x 18 . q\url('fonts/%s/%s-%s.%s') format('%s');\,
                        'material-icons',
                        $icon_key,
                        $version,
                        ($format) x 2,
                    ),
                    q\}\,
                ),
            );

            push(
                @font_style_css_blocks,
                join(
                    "\n",
                    qq\.$icon_key {\,
                    qq\    font-family                : '$icon_name';\,
                    q\    font-weight                : normal;\,
                    q\    font-style                 : normal;\,
                    q\    font-size                  : 24px;\,
                    q\    line-height                : 1;\,
                    q\    letter-spacing             : normal;\,
                    q\    text-transform             : none;\,
                    q\    display                    : inline-block;\,
                    q\    white-space                : nowrap;\,
                    q\    word-wrap                  : normal;\,
                    q\    direction                  : ltr;\,
                    q\    -moz-font-feature-settings : 'liga';\,
                    q\    -moz-osx-font-smoothing    : grayscale;\,
                    q\}\,
                ),
            );
        }

        $dest_css->child('material-icons.css')->spurt(
            join( "\n\n", @font_face_css_blocks, @font_style_css_blocks ) . "\n"
        );
    }
}

if ( $ext_yaml->{vue} ) {
    my $dest = $omni_path->child( $ext_yaml->{vue}{dest} );
    while ( my ( $src, $target ) = each %{ $ext_yaml->{vue}{libs} } ) {
        ( my $body = $ua->get( 'https://' . $src )->result->body ) =~ s/\s+$//g;
        my $save_to = $dest->child($target);
        $save_to->dirname->make_path;
        $save_to->spurt($body);
    }
}

if ( $ext_yaml->{font_awesome} ) {
    my $install = $omni_path
        ->child('install_externals_font_awesome')
        ->make_path
        ->remove_tree({ keep_root => 1 });

    my $save_to = $install->child('download.zip');

    $ua->get(
        'https://github.com/' .
        $ua
            ->get('https://github.com/FortAwesome/Font-Awesome/releases/latest')
            ->result
            ->dom
            ->find('a')
            ->map( sub { $_->attr('href') } )
            ->grep(qr|\bfontawesome\-free\-[\d\.]+\-web\.zip$|)
            ->first
    )->result->save_to( $save_to->to_string );

    system( 'cd ' . $save_to->to_abs->dirname . '; unzip -a -o -qq download.zip' );

    my $payload = path( $install->list({ dir => 1 })->grep(qr|\bfontawesome\-free\-[\d\.]+\-web$|)->first );

    my $dest = $omni_path
        ->child( $ext_yaml->{font_awesome}{dest} )
        ->make_path
        ->remove_tree({ keep_root => 1 });

    for my $part ( @{ $ext_yaml->{font_awesome}{parts} } ) {
        my $target = $dest->child($part);
        $target->dirname->make_path;
        $payload->child($part)->move_to( $target->to_string );
    }

    $install->remove_tree;
}

=head1 NAME

install_externals.pl - Install external resources into Omniframe installation

=head1 SYNOPSIS

    install_externals.pl OPTIONS
        -s, --settings FILE  # external resources YAML file (default: "config/externals.yaml")
        -d, --dir      DIR   # project's root directory (default: ".")
        -h, --help
        -m, --man

=head1 DESCRIPTION

This program will install external resources into the Omniframe installation
instance.

=head1 OPTIONS

=head2 -s, --settings

This is the relative path to the external resources YAML file.

=head2 -d, --directory

This is the new project's root directory. If not defined, it defaults to "."
or the current directory. If it doesn't exist, this directory will be created.

=head1 USAGE DETAILS

Review the default C<config/externals.yaml> file for a comprehensive example.

=head2 Google Fonts

For Google Fonts, use C<https://fonts.google.com> to search for fonts, then use
C<https://google-webfonts-helper.herokuapp.com/fonts> to help sugggest settings
for the YAML.

To deploy a Google Font, include the generated CSS (stipulated in the
C<google_fonts/dest/css> setting) in the CSS build. Then add some amount of CSS
to connect the font definition to selectors. For example:

    * {
        font-family : 'Roboto Normal', sans-serif;
    }

    h1, h2, h3, h4, h5, h6, b, strong {
        font-family : 'Roboto Bold';
        font-weight : normal;
    }

    i, em {
        font-family : 'Roboto Italic';
        font-style  : normal;
    }

    dl dt {
        font-family : 'Roboto Bold';
        font-weight : normal;
    }

=head2 Google Icons

For Google Icons, the C<browser> setting is required because Google will use it
to determine the font format to return. Setting this to a modern browser should
result in the C<woff2> format.

To deploy Google Icons, include the generated CSS (stipulated in the
C<google_fonts/dest/css> setting) in the CSS build. Then add add HTML as needed.
For example:

    <span class="material-icons-outlined">done</span>
