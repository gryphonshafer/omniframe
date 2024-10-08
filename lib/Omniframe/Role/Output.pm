package Omniframe::Role::Output;

use exact -role;
use Data::Printer return_value => 'dump', colored => 1;
use Omniframe::Util::Text;

sub dp ( $self, $params, @np_settings ) {
    return map {
        ( ref $_         ) ? "\n" . np( $_, @np_settings ) . "\n" :
        ( not defined $_ ) ? '>undef<'                            :
        ( $_ eq ''       ) ? '""'                                 : $_
    } @$params;
}

1;

=head1 NAME

Omniframe::Role::Output

=head1 SYNOPSIS

    package Package;

    use exact -class;

    with 'Omniframe::Role::Output';

    sub method ($self) {
        say $self->dp( { answer => 42 } );

        return;
    }

=head1 DESCRIPTION

This role provides some output methods.

=head1 METHODS

=head2 dp

This method accepts data along with an optional set of settings useful for
L<Data::Printer>'s C<np> method.

    say $self->dp( { answer => 42 }, @np_settings );
