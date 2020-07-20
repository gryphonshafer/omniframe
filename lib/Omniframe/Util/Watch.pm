package Omniframe::Util::Watch;

use exact 'Omniframe';
use Linux::Inotify2;
use Mojo::File 'path';

sub watch ( $self, $cb, $watches, $break = undef ) {
    $cb    //= sub {};
    $break //= \1;

    my $inotify = Linux::Inotify2->new;

    my $watch;
    $watch = sub ($object) {
        $inotify->watch(
            $object,
            IN_CLOSE_WRITE | IN_MOVED_FROM | IN_MOVED_TO | IN_CREATE | IN_DELETE,
            sub ($event) {
                my $name = $event->fullname;

                if ( $event->IN_CREATE and -d $name ) {
                    $watch->($name);
                }
                elsif (
                    $event->IN_DELETE or
                    $event->IN_CLOSE_WRITE or
                    $event->IN_MOVED_FROM or
                    $event->IN_MOVED_TO
                ) {
                    $cb->($event);
                }
            },
        );
    };

    for ( ( ref $watches eq 'ARRAY' ) ? @$watches : $watches ) {
        my $base = path($_);

        $watch->($_) for (
            grep { -d }
            map { $_->to_string } (
                $base,
                @{ $base->list_tree({ dir => 1, hidden => 1 })->to_array },
            )
        );
    }

    $inotify->poll while $$break;
}

1;

=head1 NAME

Omniframe::Util::Watch

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::Watch;

    Omniframe::Util::Watch->new->watch(
        sub ($event) {
            say $event->fullname;
        },
        '~/top_directory_of_tree_to_watch',
    );

=head1 DESCRIPTION

This class provides a single method useful for placing watches on directory
trees looking for changes, which then each trigger a callback.

=head1 METHODS

=head2 watch

This method expects a callback and either a string or arrayref of files and/or
directories to watch. Directories will be watched along with all their
containing items.

    Omniframe::Util::Watch->new->watch(
        sub ($event) {
            say $event->fullname;
        },
        \@directories_to_watch,
    );

The callback will be based a L<Linux::Inotify2::Event> object.

You can optionally pass in an additional argument: a reference to a scalar. If
the value is or becomes false, the watch loop will end.

=head1 INHERITANCE

L<Omniframe>.
