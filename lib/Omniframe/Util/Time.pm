package Omniframe::Util::Time;

use exact 'Omniframe';
use Date::Format 'time2str';
use Date::Parse 'str2time';
use DateTime::TimeZone;
use DateTime;
use Time::HiRes 'gettimeofday';

has hires   => 1;
has formats => {
    ansi   => '%Y-%m-%d %X',
    log    => '%b %e %T %Y',
    common => '%d/%b/%Y:%T %z',
    ctime  => '%C',
};

sub datetime ( $self, $format = undef, $time = time() ) {
    $time = int($time);
    return time2str(
        ( ( ref($format) ) ? $$format : $self->formats->{ $format || 'ansi' } || $self->formats->{ansi} ),
        ( ( $time =~ /^\d+$/ ) ? $time : str2time($time) ),
    );
}

sub zulu ( $self, $time = undef ) {
    $time //= ( $self->hires ) ? gettimeofday() : time();

    my $micro = ( $self->hires ) ? substr( $time - int($time), 1, 7 ) : '';
    $time     = int($time);

    my %time;
    @time{ qw(
        year month day hour minute second
    ) } = reverse( ( localtime( ( $time =~ /^\d+$/ ) ? $time : str2time($time) ) )[ 0 .. 5 ] );
    $time{year} += 1900;
    $time{month}++;

    my $time_zone = 'Etc/UTC';
    try {
        $time_zone = DateTime::TimeZone->new( name => 'local' )->name;
    }

    my $dt = DateTime->new(
        %time,
        time_zone => $time_zone,
    );
    $dt->set_time_zone('Etc/UTC');

    return $dt->stringify() . $micro . 'Z';
}

1;

=head1 NAME

Omniframe::Util::Time

=head1 SYNOPSIS

    use exact;
    use Omniframe::Util::Time;

    my $time = Omniframe::Util::Time->new;

    # print something like "2020-05-06 18:02:31"
    say $time->datetime; # defaults to using time()
    say $time->datetime(1588813351);

    # print something like "2020-05-06 18:02:31"
    say $time->datetime('ansi');

    # print something like "May  6 18:02:31 2020"
    say $time->datetime('log');

    # print something like "06/May/2020:18:02:31 -0700"
    say $time->datetime('common');

    # print something like "05/06/20 18:02:31"
    say $time->datetime( \'%c' );

    # print something like "2020-05-07T01:02:31.157612Z"
    say $time->zulu; # defaults to using time()
    say $time->zulu(1588813351.157612);

    # print something like "2020-05-07T01:02:31Z"
    $time->hires(0);
    say $time->zulu(1588813351.157612);

=head1 DESCRIPTION

This class provides methods for canonicalized date/time output. In all cases
where a method can accept an epoch, if a string of a date/time is provided
instead, that string is parsed and converted internally into an epoch.

The following print the same thing: "06/May/2020:18:02:31 -0700"

    say $time->datetime( 'common', 1588813351 );
    say $time->datetime( 'common', '2020-05-06 18:02:31' );

=head1 ATTRIBUTES

=head2 hires

Boolean value that determines if C<zulu> will return microseconds or not. It's
true by default.

=head2 formats

Hashref of format names to formats. The following formats are available by
default:

    ansi   = '%Y-%m-%d %X'
    log    = '%b %e %T %Y'
    common = '%d/%b/%Y:%T %z'
    ctime  = '%C'

=head1 METHODS

=head2 datetime

This method will accept an optional format and an optional epoch. If no epoch
is provided, it will assume now. If no format is provided, it will assume you
want "ansi".

    say $time->datetime;
    say $time->datetime('ansi')
    say $time->datetime('log');

If you want to specify your own format using the syntax defined in
L<Date::Format>, pass a reference to a string.

    $time->datetime( \'%c' );

=head2 zulu

This method prints a Javascript-consumable date/time string corrected to the
Zulu time zone:

    2020-05-07T01:02:31.157612Z

It can optionally accept an epoch. If no epoch is provided, it will assume now.

    say $time->zulu;
    say $time->zulu(1588813351.157612);

By default, this will include microseconds, but this can be switched off by
setting C<hires> to a false value.

=head1 INHERITANCE

L<Omniframe>.
