package Omniframe::Role::Template;

use exact -role;
use Mojo::File 'path';

BEGIN {
    local $SIG{__WARN__} = sub {};
    require Template;
    Template->import;
}

use HTML::Packer;

with 'Omniframe::Role::Conf';

class_has tt_version  => time;
class_has html_packer => HTML::Packer->init;

my $tt;
sub tt ( $self, $type = 'web' ) {
    unless ( $tt->{$type} ) {
        my $settings = $self->tt_settings($type);
        $tt->{$type} = Template->new( $settings->{config} );
        $settings->{context}->( $tt->{$type}->context );
    }
    return $tt->{$type};
}

sub tt_settings ( $self, $type = 'web' ) {
    my $root_dir = $self->conf->get( 'config_app', 'root_dir' );
    my $tt_conf  = $self->conf->get('template');

    my $compile_dir = $root_dir . '/' . $tt_conf->{compile_dir};
    path($compile_dir)->dirname->make_path;

    my $include_path = [ map { $root_dir . '/' . $_ } @{ $tt_conf->{$type}{include_path} } ];

    my $omniframe = $self->conf->get('omniframe');
    if ($omniframe) {
        $omniframe = path($omniframe)->to_abs;
        push( @$include_path, map { $omniframe . '/' . $_ } @{ $tt_conf->{$type}{include_path} } );
    }

    return {
        config => {
            COMPILE_EXT  => $tt_conf->{compile_ext},
            COMPILE_DIR  => $compile_dir,
            WRAPPER      => $tt_conf->{$type}{wrapper},
            INCLUDE_PATH => $include_path,
            FILTERS => {
                ucfirst => sub { return ucfirst shift },
                round   => sub { return int( $_[0] + 0.5 ) },
            },
            ENCODING  => 'utf8',
            CONSTANTS => {
                %{ $tt_conf->{$type}{constants} || {} },
            },
            VARIABLES => {
                version => $self->tt_version,
                rand    => sub { return int( rand( $_[0] // 2 ) + ( $_[1] // 0 ) ) },
                pick    => sub {
                    return ( map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { [ rand, $_ ] } @_ )[0];
                },
                %{ $tt_conf->{$type}{variables} || {} },
            },
        },
        context => sub ($context) {
            $context->define_vmethod( 'scalar', 'lower',   sub { return lc( $_[0] ) } );
            $context->define_vmethod( 'scalar', 'upper',   sub { return uc( $_[0] ) } );
            $context->define_vmethod( 'scalar', 'ucfirst', sub { return ucfirst( lc( $_[0] ) ) } );

            $context->define_vmethod( $_, 'ref', sub { return ref( $_[0] ) } ) for ( qw( scalar list hash ) );

            $context->define_vmethod( 'scalar', 'commify', sub {
                return scalar( reverse join( ',', unpack( '(A3)*', scalar( reverse $_[0] ) ) ) );
            } );

            $context->define_vmethod( 'list', 'randomize', sub {
                return map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { [ rand, $_ ] } @{ $_[0] };
            } );
        },
    };
}

sub tt_html ( $self, $tt, $data = {}, $opts = {} ) {
    $self->tt->process( $tt, $data, \ my $output ) or croak $self->tt->error;
    return $self->html_packer->minify( \$output, $opts );
}

1;

=head1 NAME

Omniframe::Role::Template

=head1 SYNOPSIS

    package Package;

    use exact -class;

    with 'Omniframe::Role::Template';

    package main;

    use exact;

    my $obj = Package->new;

    $obj->tt->process(
        \q{
            [% name | ucfirst %]
        },
        {
            name => 'omniframe',
        },
        \ my $output,
    ) or die $obj->tt->error;

=head1 DESCRIPTION

This role provides L<Template> functionality in a given class. The L<Template>
setup includes a number of TT vmethods, variables, and other TT settings.

=head1 CLASS ATTRIBUTES

=head2 tt_version

This class attribute defaults to the current timestamp.

=head2 html_packer

This class attribute contains an instantiated L<HTML::Packer> object.

=head1 METHODS

=head2 tt

This method accepts a "type" text input and returns a L<Template> object.
Internally, this method calls C<tt_settings()> to retrieve the settings for the
desired type.

Types are based on the types setup in the configuration. See L</"CONFIGURATION">
below. These types are: web and email. The default type is "web".

=head2 tt_settings

This method accepts a "type" text input and returns a hashref of L<Template>
settings suitable to be used to create a new L<Template> object.

    my $tt = Template->new( $obj->tt_settings('email') );

Types are based on the types setup in the configuration. See L</"CONFIGURATION">
below. These types are: web and email. The default type is "web".

=head2 tt_html

This method accepts a template filename as a string scalar or a template itself
as a scalar reference, then some optional data as a hashref, and then an
optional hashref of options for L<HTML::Packer>. The method will then generate
HTML and return it.

=head1 CONFIGURATION

The following is the default configuration, which can be overridden in the
application's configuration file. See L<Omniframe::Role::Conf>.

    template:
        compile_ext: .ttc
        compile_dir: local/ttc
        web:
            wrapper: wrapper.html.tt
            include_path:
                - templates/pages
                - templates/components
        email:
            include_path:
                - templates/emails

=head1 WITH ROLES

L<Omniframe::Role::Conf>.
