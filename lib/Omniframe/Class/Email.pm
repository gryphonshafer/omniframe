package Omniframe::Class::Email;

use exact 'Omniframe';
use Email::Mailer;
use Mojo::File 'path';
use Mojo::Util 'decode';

with qw( Omniframe::Role::Template Omniframe::Role::Logging );

has type    => undef;
has subject => undef;
has html    => undef;

my $settings;
my $root_dir;
my $mailer;

sub new ( $self, @params ) {
    $self = $self->SUPER::new(@params);

    croak('Failed new() because "type" must be defined') unless ( $self->type );

    $settings ||= $self->tt_settings('email');
    $root_dir ||= $self->conf->get( 'config_app', 'root_dir' );
    $mailer   ||= Email::Mailer->new(
        from    => $self->conf->get( qw( email from ) ),
        process => sub {
            my ( $template, $data ) = @_;
            my $content;
            $self->tt('email')->process( \$template, $data, \$content );
            return $content;
        },
    );

    my ($file) =
        grep { -f $_ }
        map { join( '/', $_, $self->type . '.html.tt' ) }
        @{ $settings->{config}{INCLUDE_PATH} };

    croak( 'Failed to find email template of type: ' . $self->type ) unless ($file);

    my $html    = decode( 'UTF-8', path($file)->slurp );
    my $subject = ( $html =~ s|<title>(.*?)</title>||ms ) ? $1 : '';

    $subject =~ s/\s+/ /msg;
    $subject =~ s/(^\s|\s$)//msg;

    $self->subject($subject);
    $self->html($html);

    return $self;
}

sub send ( $self, $data ) {
    $data->{subject} = \$self->subject;
    $data->{html}    = \$self->html;

    return undef unless ( $self->conf->get( 'email', 'active' ) );
    $self->info(
        'Sent email "' . $self->type . '"' . (
            ( $data->{to} and not ref $data->{to} ) ? ' to: ' . $data->{to}               :
            ( ref $data->{to} eq 'ARRAY'          ) ? ' to: ' . join( ', ', $data->{to} ) : ''
        )
    );
    return $mailer->send($data);
}

1;

=head1 NAME

Omniframe::Class::Email

=head1 SYNOPSIS

    use Omniframe::Class::Email;

    my $email = Omniframe::Class::Email->new( type => 'example' );

    $email->send({
        to   => 'example@example.com',
        data => {
            name => 'Firstname',
            url  => 'https://example.com',
        },
    });

=head1 DESCRIPTION

This class provides the means to send emails using templates stored within a
template directory as per L<Omniframe::Role::Template> configuration.

=head1 METHODS

=head2 new

This instantiation method requires the attribute C<type> be provided. This should
be the name of the template (minus suffix) to be used.

    my $email = Omniframe::Class::Email->new( type => 'example' );

The above line looks for an "example.html.tt" within the email templates
directory.

As part of the call to C<new>, the attributes C<subject> and C<html> will be
set. Subject will be pulled from the template's HTML C<title> tag, and C<html>
will be the template content.

=head2 send

This method expects parameters that would normally be sent to the C<send> method
of an L<Email::Mailer> object. The C<data> key is the data to be sent to the
template processor.

    $email->send({
        to   => 'example@example.com',
        data => {
            name => 'Firstname',
            url  => 'https://example.com',
        },
    });

=head1 CONFIGURATION

The following is the default configuration, which can be overridden in the
application's configuration file. See L<Omniframe::Role::Conf>.

    email:
        from: Example <example@example.com>
        active: 1

=head1 WITH ROLES

L<Omniframe::Role::Template>, L<Omniframe::Role::Logging>.

=head1 INHERITANCE

L<Omniframe>.
