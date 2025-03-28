#!/usr/bin/env perl
use exact -cli, -conf;
use Mojo::File 'path';
use Mojo::UserAgent;
use POSIX 'uname';
use YAML::XS 'LoadFile';

my $opt = options( qw{ settings|s=s dir|d=s clean|c local|l } );

$opt->{settings} //= q{config/externals.yaml};
$opt->{dir}      //= q{.};

my $omni_path = path( conf->get( qw( config_app root_dir ) ) );
my $proj_path = path( $opt->{dir} );
my $ext_yaml  = LoadFile( $proj_path->child( $opt->{settings} )->to_string );
my $ua        = Mojo::UserAgent->new( max_redirects => 3 );

$ua->transactor->name('Firefox/104.1');

my $target_path = ( $opt->{local} ) ? $proj_path : $omni_path;

if ( my $dart = $ext_yaml->{dart_sass} ) {
    my $dest = $target_path->child( $dart->{dest} );
    $dest->remove_tree if ( $opt->{clean} );
    $dest->make_path;

    my ( $sys_name, $node_name, $release, $version, $machine ) = uname;

    my $os =
        ( $sys_name =~ /linux/i  ) ? 'linux'   :
        ( $sys_name =~ /droid/i  ) ? 'android' :
        ( $sys_name =~ /darwin/i ) ? 'macos'   :
        ( $sys_name =~ /win/i    ) ? 'windows' :
        undef;

    my $chip =
        ( $machine =~ /(?:x86|amd)/i ) ? 'x'   :
        ( $machine =~ /arm/i         ) ? 'arm' :
        ( $machine =~ /ia/i          ) ? 'ia'  :
        undef;

    die "Unable to determin OS and/or chipset\n" unless ( $os and $chip );

    $chip .= 64 if ( $machine =~ /64/ );
    my $file = $os . '-' . $chip . ( ( $os eq 'windows' ) ? '.zip' : '.tar.gz' );

    my $tag = $ua
        ->get('https://github.com/sass/dart-sass/releases/latest')
        ->result
        ->dom
        ->find('a')
        ->map( sub { $_->attr('href') } )
        ->grep(qr|/sass/dart-sass/releases/tag/|)
        ->map( sub { m|/sass/dart-sass/releases/tag/([\d\.]+)| } )
        ->first;

    my $save_to = $dest->child("dart-sass-$tag-$file");
    $ua
        ->get("https://github.com/sass/dart-sass/releases/download/$tag/dart-sass-$tag-$file")
        ->result->save_to( $save_to->to_string );

    my $command = ( $os eq 'windows' )
        ? "unzip -o -a $save_to -d $dest"
        : "tar xvfpz $save_to --strip-components=1 -C $dest --overwrite";
    print `$command`;
    $save_to->remove;
}

if ( my $google_fonts = $ext_yaml->{google_fonts} ) {
    my $dest = $target_path->child( $google_fonts->{dest} );
    $dest->remove_tree if ( $opt->{clean} );

    my $dest_fonts = $dest->child('fonts');
    my $dest_css   = $dest->child('css');

    ( my $dest_fonts_rel_path = $google_fonts->{dest} . '/fonts' ) =~ s/^static\b/../;

    $dest_css->make_path;

    if ( my $fonts = $google_fonts->{fonts} ) {
        for my $font_name ( sort keys %$fonts ) {
            my $font_set = $fonts->{$font_name};

            ( my $font_name_camel = $font_name ) =~ s/\s+//g;

            my $font_key = lc $font_name;
            $font_key =~ s/\s+/\-/g;

            my $save_to = $dest_fonts->child( $font_key . '/download.zip' );
            $save_to->dirname->make_path;

            $ua->get(
                'https://gwfh.mranftl.com/api/fonts/' . $font_key,
                form => {
                    download => 'zip',
                    map { $_ => join( ',', @{ $font_set->{$_} } ) } qw( variants subsets formats ),
                },
            )->result->save_to( $save_to->to_string );

            my $target = $save_to->to_abs->dirname;
            print `unzip -o -a $save_to -d $target`;
            unlink( $save_to->to_string );

            my $metadata = [];
            $save_to->to_abs->dirname->list->each( sub {
                my ( $pre, $version, $post ) = $_->basename =~ /^(.+)\-v(\d+)\-(.+)$/;
                if (
                    $save_to->to_abs->dirname->list->first( sub {
                        my ( $this_pre, $this_version, $this_post ) = $_->basename =~ /^(.+)\-v(\d+)\-(.+)$/;
                        $this_pre eq $pre and $this_post eq $post and $this_version > $version;
                    } )
                ) {
                    $_->remove;
                }
                else {
                    my @parts = split( /[\-\.]/,
                        substr(
                            $_->basename,
                            length($font_key) + 1 + length($version),
                        )
                    );

                    my ( $format, $variant ) = ( pop @parts, pop @parts );
                    shift @parts;

                    my $style   = ( $variant =~ /italic/ ) ? 'italic' : 'normal';
                    my $weight  = ( $variant =~ /(\d+)/  ) ? $1       : 400;

                    push( @$metadata, {
                        style   => $style,
                        weight  => $weight,
                        variant => $variant,
                        subsets => join( '-', @parts ),
                    } ) if (
                        not @$metadata or
                        $metadata->[-1]{style} ne $style or
                        $metadata->[-1]{weight} ne $weight or
                        $metadata->[-1]{variant} ne $variant
                    );

                    push( @{ $metadata->[-1]{formats} }, $format );
                }
            } );

            my ($version) = substr(
                $save_to->to_abs->dirname->list->first->basename,
                length $font_key,
            ) =~ /\-(v\d+)/;

            my $css = $dest_css->child( $font_key . '.css' );
            $css->spew(
                join( "\n\n", map {
                    my $this = $_;
                    join(
                        "\n",
                        q\@font-face {\,
                        qq\    font-family : '$font_name';\,
                        qq\    font-style  : $this->{style};\,
                        qq\    font-weight : $this->{weight};\,
                        (
                            ( grep { $_ eq 'eot' } map { $_->{format} } @{ $this->{src} } ) ? (
                                sprintf(
                                    q\    src         : url('\ . $dest_fonts_rel_path .
                                        q\/%s/%s-%s-%s-%s.%s');\,
                                    $font_key,
                                    $font_key,
                                    $version,
                                    $this->{subsets},
                                    $this->{variant},
                                    'eot',
                                )
                            ) : ()
                        ),
                        q\    src         : local(''),\,
                        join( ",\n", map {
                            sprintf(
                                ' ' x 8 . q\url('\ . $dest_fonts_rel_path .
                                    q\/%s/%s-%s-%s-%s.%s') format('%s')\,
                                $font_key,
                                $font_key,
                                $version,
                                $this->{subsets},
                                $this->{variant},
                                (
                                    ( $_ eq 'eot' ) ? $_ . '?#iefix'              :
                                    ( $_ eq 'svg' ) ? $_ . '#' . $font_name_camel : $_
                                ),
                                (
                                    ( $_ eq 'eot' ) ? 'embedded-opentype' :
                                    ( $_ eq 'ttf' ) ? 'truetype'          : $_
                                ),
                            )
                        } @{ $this->{formats} } ) . ';',
                        q\}\,
                    );
                } @$metadata ) . "\n",
                'UTF-8',
            );
            say $css;
        }
    }

    if ( my $icons = $google_fonts->{icons} ) {
        my $type_ua_map = {
            woff2 => 'Firefox/104.1',
            woff  => 'Firefox/30.0',
            ttf   => 'Mozilla/5.0',
            eot   => 'MSIE 7.0',
        };

        my $save_to = $dest_fonts->child('material-icons')->make_path;

        my @targets;
        for my $icon_name ( @{ $icons->{types} } ) {
            my ($icon_url) = $ua->get(
                'https://fonts.googleapis.com/icon', form => { family => $icon_name },
            )->result->body =~ /src:\s*url\(([^\)]+)\)/;

            my ($version) = $icon_url =~ m|/(v\d+)/|;
            ( my $icon_key = lc $icon_name ) =~ s/\s+/\-/g;

            my $ua_name = $ua->transactor->name;
            for my $format ( @{ $icons->{formats} || ['woff2'] } ) {
                $ua->transactor->name( $type_ua_map->{$format} );
                my $target = $save_to->child( $icon_key . '-' . $version . '.' . $format )->to_string;
                $ua->get($icon_url)->result->save_to($target);
                push( @targets, $target );
                say $target;
            }
            $ua->transactor->name($ua_name);
        }

        $save_to->list->each( sub {
            my ( $pre, $version, $post ) = $_->basename =~ /^(.+)\-v(\d+)\.(.+)$/;
            $_->remove if (
                $save_to->list->first( sub {
                    my ( $this_pre, $this_version, $this_post ) = $_->basename =~ /^(.+)\-v(\d+)\.(.+)$/;
                    $this_pre eq $pre and $this_post eq $post and $this_version > $version;
                } )
            );
        } );

        my %icons;
        $save_to->list->each( sub {
            my @parts                    = split( /[\-\.]/, $_->basename );
            my ( $format, $version )     = ( pop @parts, pop @parts );
            my $icon_key                 = join( '-', @parts );
            $icons{$icon_key}{icon_name} = join( ' ', map { ucfirst } @parts );
            $icons{$icon_key}{version}   = $version;

            push( @{ $icons{$icon_key}{formats} }, $format );
        } );

        my ( @font_face_css_blocks, @font_style_css_blocks );
        for my $icon_key ( sort keys %icons ) {
            push(
                @font_face_css_blocks,
                join(
                    "\n",
                    q\@font-face {\,
                    qq\    font-family : '$icons{$icon_key}{icon_name}';\,
                    q\    font-style  : normal;\,
                    q\    font-weight : 400;\,
                    (
                        ( grep { $_ eq 'eot' } @{ $icons{$icon_key}{formats} || [] } ) ? (
                            sprintf(
                                q\    src         : url('\ . $dest_fonts_rel_path . q\/%s/%s-%s.%s');\,
                                $icon_key,
                                $icons{$icon_key}{version},
                                'eot',
                            )
                        ) : ()
                    ),
                    q\    src         : local(''),\,
                    join( ",\n", map {
                        sprintf(
                            ' ' x 8 . q\url('\ . $dest_fonts_rel_path . q\/%s/%s-%s.%s') format('%s')\,
                            'material-icons',
                            $icon_key,
                            $icons{$icon_key}{version},
                            ( ( $_ eq 'eot' ) ? $_ . '?#iefix' : $_ ),
                            (
                                ( $_ eq 'eot' ) ? 'embedded-opentype' :
                                ( $_ eq 'ttf' ) ? 'truetype'          : $_
                            ),
                        )
                    } @{ $icons{$icon_key}{formats} || ['woff2'] } ) . ';',
                    q\}\,
                ),
            );

            push(
                @font_style_css_blocks,
                join(
                    "\n",
                    qq\.$icon_key {\,
                    qq\    font-family                : '$icons{$icon_key}{icon_name}';\,
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

        my $css = $dest_css->child('material-icons.css');
        $css->spew( join( "\n\n", @font_face_css_blocks, @font_style_css_blocks ) . "\n", 'UTF-8' );
        say $css;
    }
}

if ( my $vue = $ext_yaml->{vue} ) {
    my $dest = $target_path->child( $vue->{dest} );
    $dest->remove_tree if ( $opt->{clean} );

    while ( my ( $src, $target ) = each %{ $vue->{libs} } ) {
        ( my $body = $ua->get( 'https://unpkg.com/' . $src )->result->body ) =~ s/\s+$//g;
        my $save_to = $dest->child($target);
        $save_to->dirname->make_path;
        $save_to->spew( $body, 'UTF-8' );
        say $save_to;
    }
}

if ( my $font_awesome = $ext_yaml->{font_awesome} ) {
    my $dest = $target_path->child( $font_awesome->{dest} );
    $dest->remove_tree if ( $opt->{clean} );
    $dest->make_path;

    my $save_to = $dest->child('download.zip');

    $ua->get(
        'https://github.com/' .
        $ua->get(
            'https://github.com/FortAwesome/Font-Awesome/releases/expanded_assets/' . $ua
                ->get('https://github.com/FortAwesome/Font-Awesome/releases/latest')
                ->result
                ->dom
                ->find('a')
                ->map( sub { $_->attr('href') } )
                ->grep(qr|/FortAwesome/Font-Awesome/releases/tag/|)
                ->map( sub { m|/FortAwesome/Font-Awesome/releases/tag/([\d\.]+)| } )
                ->first,
        )
            ->result
            ->dom
            ->find('a')
            ->map( sub { $_->attr('href') } )
            ->grep(qr|\bfontawesome\-free\-[\d\.]+\-web\.zip$|)
            ->first
    )->result->save_to( $save_to->to_string );

    for my $part ( $font_awesome->{parts}->@* ) {
        my $target = $save_to->dirname->child($part)->dirname;
        $target->make_path;
        print `unzip -o -a -j $save_to "*/$part" -d $target`;
    }

    $save_to->remove;
}

=head1 NAME

install_externals.pl - Install external resources into Omniframe installation

=head1 SYNOPSIS

    install_externals.pl OPTIONS
        -s, --settings FILE  # external resources YAML file (default: "config/externals.yaml")
        -d, --dir      DIR   # project's root directory (default: ".")
        -c, --clean          # turns on a "clean" install
        -l, --local          # install in project dir (instead of omniframe dir)
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

=head2 -c, --clean

Remove any existing, previously installed external resources before installing.
Use this with caution when there are multiple projects storing their installed
externals with the Omniframe installation directory structure.

=head2 -l, --local

Install in the project's local directory (project's root director) instead of
into the Omniframe installation instance.

=head1 USAGE DETAILS

Review the default C<config/externals.yaml> file for a comprehensive example.

=head2 Google Fonts

For Google Fonts, use C<https://fonts.google.com> to search for fonts, then use
C<https://gwfh.mranftl.com/fonts> to help sugggest settings for the YAML.

=head2 Google Icons

For Google Icons, the C<browser> setting is required because Google will use it
to determine the font format to return. Setting this to a modern browser should
result in the C<woff2> format.

To deploy Google Icons, include the generated CSS (stipulated in the
C<google_fonts/dest/css> setting) in the CSS build. Then add add HTML as needed.
For example:

    <span class="material-icons-outlined">done</span>
