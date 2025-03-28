package Omniframe::Mojo::Document;

use exact -conf, 'Omniframe';
use File::Find 'find';
use Mojo::File;
use Mojo::Util 'decode';
use Text::CSV_XS 'csv';
use Text::MultiMarkdown 'markdown';

with 'Omniframe::Role::Logging';

sub document_helper ($self) {
    return sub ( $c, $file, $payload_process = undef, $file_filter = undef ) {
        my $paths = [ grep { defined }
            conf->get( qw( config_app root_dir ) ),
            conf->get('omniframe'),
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
            $self->notice( '404 in ' . __PACKAGE__ . ' content: ' . ( $file || '>undef<' ) );

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
            my $payload = decode( 'UTF-8', $asset->slurp('UTF-8') );

            ( my $name = $file ) =~ s/\.[^\.\/]+$//;
            $name =~ s|/_|/|g;
            $name =~ s/$file_filter// if ($file_filter);

            $c->stash( title => join( ' / ',
                map {
                    ucfirst( join( ' ', map {
                        ( /^(?:a|an|the|and|but|or|for|nor|on|at|to|from|by)$/i ) ? $_ : ucfirst
                    } split('_') ) )
                } split( '/', $name )
            ) );

            $payload = $payload_process->( $payload, $type ) if ( ref $payload_process eq 'CODE' );

            return $c->stash( html => markdown($payload)     ) if ( $type eq 'md'  );
            return $c->stash( csv  => csv( in => \$payload ) ) if ( $type eq 'csv' );
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

sub docs_nav_helper ($self) {
    return sub (
        $c,
        $relative_docs_dir = '',
        $home_type         = 'md',
        $home_name         = 'Home Page',
        $home_title        = 'Home Page',
    ) {
        my $docs_dir = conf->get( qw( config_app root_dir ) ) . '/' . $relative_docs_dir;

        my @files;
        find(
            {
                wanted => sub {
                    push( @files, $File::Find::name ) if (
                        /\.(?:md|csv|pdf|xls|xlsx|xlsm|xlsb|doc|docx|ppt|pptx)$/i
                    );
                },
                preprocess => sub {
                    sort {
                        ( $a eq 'index.md' and $b ne 'index.md' ) ? 0 :
                        ( $a ne 'index.md' and $b eq 'index.md' ) ? 1 :
                        lc $a cmp lc $b
                    } @_;
                },
            },
            $docs_dir,
        );

        my $docs_dir_length = length($docs_dir) + ( ( length($relative_docs_dir) ) ? 1 : 0 );
        my $docs_nav        = [];

        for (@files) {
            next if (m|/_[^_]|);

            my $href = substr( $_, $docs_dir_length );
            my @path = ( $home_name, map {
                ucfirst( join( ' ', map {
                    ( /^(?:a|an|the|and|but|or|for|nor|on|at|to|from|by)$/i ) ? $_ : ucfirst
                } split('_') ) )
            } split( /\/|\.[^\.]+$/, $href ) );

            my $type = (/\.([^\.]+)$/) ? lc($1) : '';
            $type =~ s/x$// if ( length $type == 4 );

            my $name = pop @path;
            $name = decode( 'UTF-8', $name ) // $name;
            my $title = $name;

            if ( $type eq 'md' ) {
                my $content = Mojo::File->new($_)->slurp('UTF-8');
                my @headers = $content =~ /^\s*(#[^\n]*)/msg;
                ( $title = $headers[0] ) =~ s/^\s*#+\s*//g if ( $headers[0] );
            }
            $title = decode( 'UTF-8', $title ) // $title;

            my $set = $docs_nav;
            my $parent;

            for my $node (@path) {
                my @items = grep { $_->{folder} and $_->{folder} eq $node } @$set;
                $parent   = $set;

                if (@items) {
                    $items[0]->{nodes} = [] unless ( $items[0]->{nodes} );
                    $set = $items[0]->{nodes};
                }
                else {
                    my $nodes = [];
                    push( @$set, {
                        folder => $node,
                        nodes  => $nodes,
                    } );
                    $set = $nodes;
                }
            }

            if ( $name eq 'Index' ) {
                $parent->[-1]{href}  = '/' . $href;
                $parent->[-1]{title} = $title;
                delete $parent->[-1]{nodes};
            }
            else {
                push( @$set, {
                    name  => $name,
                    href  => '/' . $href,
                    title => $title,
                    type  => $type,
                } );
            }
        }

        push( @$docs_nav, @{ delete $docs_nav->[0]{nodes} } );

        $docs_nav->[0]{name}  = delete $docs_nav->[0]{folder};
        $docs_nav->[0]{href}  = '/';
        $docs_nav->[0]{title} = $home_title;
        $docs_nav->[0]{type}  = $home_type;

        return $docs_nav;
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
        my $document = Omniframe::Mojo::Document->new;
        $self->helper( document => $document->document_helper );
        $self->helper( docs_nav => $document->docs_nav_helper );

        $self->routes->any( '/docs/*name' => { name => 'index.md' } => sub ($c) {
            $c->document( $c->stash('name') );
            $c->render( text => $c->stash('html') ) if ( $c->stash('html') );
        } );

        $self->routes->any( '/*null' => { null => undef } => sub ($c) {
            $c->stash( docs_nav => $c->docs_nav );
            $c->render( template => 'example/index' );
        } );
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

This package also provides the ability to setup a "docs_nav" helper to return a
data structure of document files.

=head1 METHODS

=head2 document_helper

This method will return a subroutine reference that can be used in a
Mojolicious helper.

    $self->helper( document => Omniframe::Mojo::Document->new->document_helper );

This helper once set can be called with a path to a file asset, assuming root
is the project's root directory.

    $self->routes->any( '/docs/*name' => { name => 'index.md' } => sub ($c) {
        $c->document( $c->stash('name') );
        $c->render( text => $c->stash('html') ) if ( $c->stash('html') );
    } );

You can optionally pass a subroutine reference that will be passed any MD or CSV
payload just prior to processing it into its final form.

=head2 docs_nav_helper

This method will return a subroutine reference that can be used in a
Mojolicious helper.

    $self->helper( docs_nav => Omniframe::Mojo::Document->new->docs_nav_helper );

This helper once set can be called with the relative-to-the-project's-root path
of a documents directory. You can optionally pass in a file type and title for
the base/root page.

    my $docs_nav = $self->docs_nav( 'docs', 'md', 'Home Page' );

What will be returned is a data structure of the documents directory suitable
for use in a navigation menu.

=head1 WITH ROLE

L<Omniframe::Role::Logging>.

=head1 INHERITANCE

L<Omniframe>.
