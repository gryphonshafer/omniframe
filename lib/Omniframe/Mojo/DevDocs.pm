package Omniframe::Mojo::DevDocs;

use exact -conf, 'Omniframe';
use Mojo::DOM;
use Mojo::File 'path';
use Mojo::Util 'url_unescape';
use Omniframe::Util::File 'opath';
use Pod::Simple::HTML;
use Template;
use Text::MultiMarkdown 'markdown';

class_has template => opath('templates/pages/devdocs.html.tt')->slurp('UTF-8');
class_has tt       => sub { Template->new };

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
                $_->[1] = conf->get( @{ $_->[1] } );
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
                        sort {
                            $a->{sort} cmp $b->{sort}
                        }
                        map {
                            my $node = $_->to_rel->to_string;

                            $node = substr( $node, length( $root_dirs->[-1]->{dir} ) + 1 )
                                if ( $tree->{name} eq 'Omniframe' and @$root_dirs > 1 );

                            my $filename = $node;
                            my $type     = ( $filename =~ s:^(lib)/:: ) ? 'lib' : 'file';
                            my $name     = [ split( m|/+|, $filename ) ];

                            +{
                                name => $name,
                                type => $type,
                                url  => $c->url_for( join( '/', $location, $tree->{name}, $node ) ),
                                sort => join( '/', @$name[ 0 .. @$name - 2 ] ),
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
                $data->{content} = markdown( $file->slurp('UTF-8') );
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
                $data->{content} = '<pre>' . $file->slurp('UTF-8') . '</pre>';
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

=head1 INHERITANCE

L<Omniframe>.

=cut
