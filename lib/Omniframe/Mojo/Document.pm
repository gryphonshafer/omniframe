package Omniframe::Mojo::Document;

use exact 'Omniframe';
use Mojo::Util 'decode';
use Text::CSV_XS 'csv';
use Text::MultiMarkdown 'markdown';

with qw( Omniframe::Role::Conf Omniframe::Role::Logging );

sub helper ($self) {
    return sub ( $c, $file, $content_type = undef ) {
        my $paths = [ grep { defined }
            $self->conf->get( qw( config_app root_dir ) ),
            $self->conf->get('omniframe'),
        ];

        my $pathfile;
        for (@$paths) {
            if ( -f $_ . '/' . $file ) {
                $pathfile = $_ . '/' . $file;
                last;
            }
            elsif ( -f $_ . '/' . $file . '/index.md' ) {
                $pathfile = $_ . '/' . $file . '/index.md';
                last;
            }
        }

        unless ($pathfile) {
            $self->notice( '404 in Main content: ' . ( $file || '>undef<' ) );

            my $default_handler = $c->app->renderer->default_handler;
            $c->app->renderer->default_handler('ep');
            $c->reply->not_found;
            $c->rendered(404);
            $c->app->renderer->default_handler($default_handler);
            return;
        }

        my ($type) = lc($file) =~ /\.([^\.\/]+)$/;
        $type ||= '';

        my $asset = Mojo::Asset::File->new( path => $pathfile );

        if ( not $c->param('download') and ( $type eq 'md' or $type eq 'csv' ) ) {
            my $payload = decode( 'UTF-8', $asset->slurp );

            ( my $name = $file ) =~ s/\.[^\.\/]+$//;
            $name =~ s|/_|/|g;
            $c->stash( title => join( ' / ',
                map {
                    ucfirst( join( ' ', map {
                        ( /^(?:a|an|the|and|but|or|for|nor|on|at|to|from|by)$/i ) ? $_ : ucfirst
                    } split('_') ) )
                } split( '/', $name )
            ) );

            return $c->stash( html => markdown($payload) ) if ( $type eq 'md' );
            return $c->stash( csv => csv( in => \$payload ) ) if ( $type eq 'csv' );
        }

        my ($filename) = $file =~ /\/([^\/]+)$/;

        $c->res->headers->content_type(
            ( $c->app->types->type($type) || 'application/x-download' ) . ';name=' . $filename
        );
        $c->res->headers->content_length( $asset->size );
        $c->res->content->asset($asset);

        return $c->rendered(200);
    };
}

1;

=head1 NAME

Omniframe::Mojo::Document

=head1 SYNOPSIS

    package Project::Control;

    use exact 'Omniframe::Control';
    use Omniframe::Mojo::Document;

    sub startup ($self) {
        $self->helper( socket => Omniframe::Mojo::Document->new->helper );

        my $r = $self->routes;

        $r->any( '/sw.js' => sub ($c) {
            return $c->document('/static/js/util/sw.js')
        } );

        return;
    }

=head1 DESCRIPTION

This package provides methods to enable setup of a "document" helper that can
be called to serve arbitrary files.

If the file is Markdown (meaning the filename has a ".md" suffix), it will be
converted to HTML and stored as "html" in L<Mojolicious> C<stash>. If the file
is CSV (meaning the filename has a ".csv" suffix), it will be loaded into "csv"
in L<Mojolicious> C<stash>. In either of these cases, the filename will be
converted into a reasonable page title and stored as "title" in L<Mojolicious>
C<stash>. In all other cases, the contents of the file will be rendered using
some reasonable assumptions based on the file name's suffix.

=head1 METHODS

=head2 helper

This method will return a subroutine reference that can be used in a
Mojolicious helper.

    $self->helper( document => Omniframe::Mojo::Document->new->helper );

This helper once set can be called with a path to a file asset, assuming root
is the project's root directory.

    $self->routes->any( '/sw.js' => sub ($c) {
        return $c->document('/static/js/util/sw.js')
    } );

=head1 WITH ROLES

L<Omniframe::Role::Conf>, L<Omniframe::Role::Logging>.

=head1 INHERITANCE

L<Omniframe>.
