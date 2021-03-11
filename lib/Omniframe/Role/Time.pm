package Omniframe::Role::Time;

use exact -role;
use Omniframe::Class::Time;

my $time = Omniframe::Class::Time->new;
class_has time => $time;

1;

=head1 NAME

Omniframe::Role::Time

=head1 SYNOPSIS

    package Package;

    use exact -class;

    with 'Omniframe::Role::Time';

    sub zulu ( $self, $input ) {
        return $self->time->zulu($input);
    }

=head1 DESCRIPTION

This role provides a single C<time> class attribute which is an application-wide
singleton L<Omniframe::Class::Time> object with the application's configuration.

=head1 CLASS ATTRIBUTES

=head2 time

This class attribute, when accessed, will become an application-wide singleton
L<Omniframe::Class::Time> object with the application's configuration.
