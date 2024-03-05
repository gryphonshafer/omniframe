package Omniframe::Mojo::DevDocs;

use exact 'Omniframe';
use Mojo::DOM;
use Mojo::File 'path';
use Mojo::Util 'url_unescape';
use Pod::Simple::HTML;
use Template;
use Text::MultiMarkdown 'markdown';

with 'Omniframe::Role::Conf';

class_has template => join( '', <DATA> );
class_has tt       => Template->new;

sub setup ( $self, $app, $location ) {
    $app->routes->any( $location . '*pathinfo' => { pathinfo => '' } => sub ($c) {
        ( my $app_name = ref $c->app ) =~ s/::.*//;

        my $data      = { title => "$app_name DevDocs" };
        my $root_dirs = [
            map {
                +{
                    name => $_->[0],
                    dir  => $_->[1],
                    path => path( $_->[1] ),
                };
            }
            grep { defined $_->[1] }
            map {
                $_->[1] = $self->conf->get( @{ $_->[1] } );
                $_;
            } (
                [ $app_name => [ qw( config_app root_dir ) ] ],
                [ Omniframe => [ 'omniframe'               ] ],
            )
        ];

        if ( not $c->stash('pathinfo') or $c->stash('pathinfo') =~ m|^/+$| ) {
            $data->{header} = "$app_name DevDocs";
            $data->{trees}  = [
                map {
                    my $tree = $_;

                    $tree->{files} = [
                        map {
                            my $node = $_->to_rel->to_string;

                            $node = substr( $node, length( $root_dirs->[-1]->{dir} ) + 1 )
                                if ( $tree->{name} eq 'Omniframe' );

                            my $filename = $node;
                            my ($type)   = ( $filename =~ s:^(lib)/:: ) ? $1 : '';

                            if ( $type eq 'lib' ) {
                                $filename =~ s|/+|::|g;
                                $filename =~ s|\.pm$||;
                            }
                            else {
                                $filename = [ split( m|/+|, $filename ) ];
                            }

                            +{
                                name => $filename,
                                url  => $c->url_for( join( '/', $location, $tree->{name}, $node ) ),
                            };
                        }
                        @{ $tree->{path}->list_tree->grep( qr/\.(md|pm|pl?)$/i )->to_array }
                    ];

                    $tree;
                }
                @$root_dirs
            ];
        }
        else {
            my ( $project, $path ) = $c->stash('pathinfo') =~ m|^/?([^/]+)/(.+)|;
            my $file = $root_dirs->[ ( $project eq $app_name ) ? 0 : -1 ]->{path}->child($path);

            $data->{extname} = lc $file->extname;
            $data->{title} .= ': ' . $file->to_rel->to_string;

            $data->{home_title}    = "$app_name DevDocs";
            $data->{home_location} = $location;

            if ( $data->{extname} eq 'md' ) {
                $data->{type}    = 'md';
                $data->{content} = markdown( $file->slurp );
            }
            elsif ( $data->{extname} eq 'pm' or $data->{extname} eq 'pl' ) {
                $data->{type} = 'pod';

                my $p = Pod::Simple::HTML->new;
                $p->output_string( \my $raw_html );
                $p->parse_file( $file->to_abs->to_string );

                if ($raw_html) {
                    my $dom = Mojo::DOM->new($raw_html)->at('body');
                    $dom->descendant_nodes->grep( sub { $_->type eq 'comment' } )->each( sub{ $_->remove } );

                    $dom->find('a')->grep( sub {
                        $_->attr('href') and $_->attr('href') =~ m|\bmetacpan.org/pod\b|
                    } )->each( sub ( $anchor, @stuff ) {
                        my ($target) = $anchor->attr('href') =~ m|\bmetacpan.org/pod/(.+)|;
                        ( $target = url_unescape($target) ) =~ s|::|/|g;
                        $target =~ s|#|/|;

                        DIR: for my $dir ( @$root_dirs ) {
                            for (
                                [ '', '' ],
                                [ 'lib/', '.pm' ],
                                [ 'tools/', '' ],
                            ) {
                                my $file = $dir->{path}->child( $_->[0] . $target . $_->[1] );

                                if ( $file->stat ) {
                                    $anchor->attr( href =>
                                        $c->url_for(
                                            join( '/',
                                                $location,
                                                $dir->{name},
                                                $file->to_rel->to_string,
                                            )
                                        )
                                    );
                                    last DIR;
                                }
                            }
                        }
                    } );

                    $data->{content} = $dom->content;
                }
                else {
                    $data->{content} = 'No POD found in: ' . $file->to_rel->to_string;
                }
            }
            else {
                $data->{content} = '<pre>' . $file->slurp . '</pre>';
            }
        }

        $self->tt->process( \$self->template, $data, \my $content );
        $c->render( data => $content );

        return;
    } );

    return;
}

1;

=head1 NAME

Omniframe::Mojo::DevDocs

=head1 SYNOPSIS

    package Project::Control;

    use exact 'Omniframe::Control';
    use Omniframe::Mojo::DevDocs;

    sub startup ($self) {
        Omniframe::Mojo::DevDocs->new->setup( $self, '/devdocs' );
        return;
    }

=head1 DESCRIPTION

This package provides a method to setup "devdocs" support for a project. What
this means in practice is that you'll have routes setup under "/devdocs" (or
whatever you pass in as the second argument to override this default) that will
provide a list of files that probably contain POD or Markdown. When any of those
links are clicked, the POD or Markdown is rendered.

=head1 METHODS

=head2 setup

This method expects the application object and an optional override root path
for the routes to setup. (It defaults to "/devdocs".)

=head1 WITH ROLES

L<Omniframe::Role::Conf>.

=head1 INHERITANCE

L<Omniframe>.

=cut

__DATA__
<!DOCTYPE html>
<html>
    <head>
        <title>[% title %]</title>

        <meta charset="utf-8">
        <meta name="robots" content="noindex">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">

        <style type="text/css">
            body {
                margin-left  : 3em;
                margin-right : 3em;
                margin-top   : 3em;
                margin-bottom: 3em;
                font-family  : sans-serif;
                font-size    : 14px;
                line-height  : 1.5em;
            }

            section {
                page-break-inside: avoid;
            }

            h1 {
                margin        : 1em 0 0.7em -0.7em;
                font-size     : 150%;
                padding-bottom: 12pt;
                border-bottom : 1px solid gainsboro;
            }

            h2 {
                margin        : 1.4em 0 0.7em -0.7em;
                font-size     : 130%;
                padding-bottom: 6pt;
            }

            h3 {
                margin   : 1.4em 0 0.7em -0.7em;
                font-size: 120%;
            }

            h4 {
                margin   : 1.4em 0 0.7em -0.7em;
                font-size: 110%;
            }

            h5 {
                margin   : 1.4em 0 0.7em -0.7em;
                font-size: 105%;
            }

            h6 {
                margin   : 1.4em 0 0.7em -0.7em;
                font-size: 100%;
            }

            dt {
                margin-left: 1em;
                font-weight: bold;
            }

            dd {
                margin-bottom: 1em;
            }

            table {
                border-collapse: collapse;
            }

            table,
            table th,
            table td {
                border: 1px solid gainsboro;
            }

            th, td {
                padding: 0.35em 0.7em;
            }

            tr:nth-child(even) td {
                background-color: whitesmoke;
            }

            pre, code {
                background-color: whitesmoke;
                font-family     : monospace;
                font-size       : 13px;
            }

            pre {
                padding      : 1.0em 1.25em;
                border-radius: 0.5em;
                line-height  : 1.25em;
                border       : 1px solid lightgray;
            }

            code {
                border-radius: 0.25em;
                padding      : 0.02em 0.25em;
            }

            pre > code {
                border-radius: 0;
                padding      : 0;
                white-space  : pre-wrap;
            }

            blockquote {
                color       : gray;
                border-left : 0.3em solid lightgray;
                padding-left: 1em;
                margin-left : 0;
            }

            p.home_location {
                float     : right;
                margin-top: 0;
            }

            @media only print {
                body {
                    font-size    : 10pt;
                    margin-left  : 1.3em;
                    margin-right : 0.2em;
                    margin-top   : 0.2em;
                    margin-bottom: 0.2em;
                }

                a {
                    text-decoration: none;
                    color          : black;
                }

                p.home_location {
                    display: none;
                }
            }
        </style>
    </head>
    <body>
        [% IF home_location %]
            <p class="home_location"><a
                href="[% home_location %]">[% home_title %]</a></p>
        [% END %]

        [% IF header %]<h1>[% header %]</h1>[% END %]

        [% FOR tree IN trees %]
            <h2>[% tree.name %]</h2>

            [% IF tree.files.size %]
                <ul>
                    [% FOR file IN tree.files %]
                        [%
                            name = '';
                            path = [];

                            IF file.name.ref;
                                name = file.name.pop;
                                path = file.name;
                            ELSE;
                                name = file.name;
                            END;
                        %]
                        <li>
                            [% FOR part IN path %][% part %]/[% END %]<a href="[% file.url %]">[% name %]</a>
                        </li>
                    [% END %]
                </ul>
            [% END %]
        [% END %]

        [% IF content %]
            <div class="[% type %]">[% content %]</div>
        [% END %]
    </body>
</html>
