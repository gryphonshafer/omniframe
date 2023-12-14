package Omniframe::Class::Time;

use exact 'Omniframe';
use Date::Format 'time2str';
use Date::Parse qw( str2time strptime );
use DateTime::TimeZone::Olson 'olson_country_selection';
use DateTime::TimeZone;
use DateTime;
use Time::HiRes 'gettimeofday';
use YAML::XS 'LoadFile';

with 'Omniframe::Role::Conf';

has hires   => 1;
has formats => {
    ansi   => '%Y-%m-%d %T',
    log    => '%b %e %T %Y',
    common => '%d/%b/%Y:%T %z',
    ctime  => '%C',
};

has olson_zones => sub ($self) {
    my $olson_zones;
    my $country_population = LoadFile(
        (
            $self->conf->get( qw( config_app root_dir ) ) . '/' . ( $self->conf->get('omniframe') // '' )
        ) . '/config/population.yaml'
    );

    my $olson_country_selection = olson_country_selection;
    for my $country ( keys %$olson_country_selection ) {
        for my $region ( keys %{ $olson_country_selection->{$country}{regions} } ) {
            $olson_zones->{ $olson_country_selection->{$country}{regions}{$region}{timezone_name} } = {
                %{ $olson_country_selection->{$country}{regions}{$region} },
                population => $country_population->{ $olson_country_selection->{$country}{olson_name} } // 1,
            };
        }
    }

    return $olson_zones;
};

sub datetime ( $self, $format = undef, $time = time(), $time_zone = 'UTC' ) {
    $time = int($time) if ( $time =~ /^\d+\.\d+$/ );
    return time2str(
        ( ( ref($format) ) ? $$format : $self->formats->{ $format || 'ansi' } || $self->formats->{ansi} ),
        ( ( $time =~ /^\d+$/ ) ? $time : str2time( $time, $time_zone ) ),
    );
}

sub zulu ( $self, $time = undef, $time_zone = 'UTC' ) {
    $time = str2time( $time, $time_zone ) if ( $time and $time !~ /^\d+(?:\.\d+)?$/ );
    $time //= ( $self->hires ) ? gettimeofday() : time();

    my $micro = ( $self->hires ) ? substr( $time - int($time), 1, 7 ) : '';
    $time     = int($time);

    try {
        $time_zone = DateTime::TimeZone->new( name => 'local' )->name;
    }
    catch ($e) {}

    my $dt = DateTime->from_epoch(
        epoch     => $time,
        time_zone => $time_zone,
    );
    $dt->set_time_zone('UTC');

    return $dt->stringify . $micro . 'Z';
}

sub zones ( $self, $time = time() ) {
    my $dt = ( eval { $time->isa('DateTime') } ) ? $time : DateTime->from_epoch( epoch => $time );

    return [
        sort {
            $a->{offset} <=> $b->{offset} or
            $a->{name} cmp $b->{name}
        }
        grep { defined }
        map {
            my $offset;
            try {
                $offset = DateTime::TimeZone->new( name => $_ )->offset_for_datetime($dt);
            }
            catch ($e) {}

            if ($offset) {
                my $description   = $self->olson_zones->{$_}{olson_description};
                my $offset_string = DateTime::TimeZone->offset_as_string( $offset, ':' );
                my $name_parts    = [
                    map { s/_/ /gr }
                    split( '/', $self->olson_zones->{$_}{timezone_name} )
                ];

                +{
                    name          => $self->olson_zones->{$_}{timezone_name},
                    name_parts    => $name_parts,
                    description   => $description,
                    offset        => $offset,
                    offset_string => $offset_string,
                    label         => '(GMT' . $offset_string . ') ' .
                        join( ' - ', @$name_parts ) .
                        ( ($description) ? ' [' . $description . ']' : '' )
                };
            }
            else {
                undef;
            }
        }
        keys %{ $self->olson_zones }
    ];
}

sub olson ( $self, $offset, $time = time() ) {
    my $dt = ( eval { $time->isa('DateTime') } ) ? $time : DateTime->from_epoch( epoch => $time );
    $offset = int $offset;

    my ($time_zone) =
        sort {
            $b->{population} <=> $a->{population} or
            $a->{name_complexity} <=> $b->{name_complexity} or
            $b->{olson_description_exists} <=> $a->{olson_description_exists} or
            $a->{olson_description_length} <=> $b->{olson_description_length}
        }
        map {
            $_->{olson_description_exists} = ( length $_->{olson_description} ) ? 1 : 0;
            $_->{olson_description_length} = length $_->{olson_description};
            $_->{name_complexity}          = scalar( split( /\//, $_->{timezone_name} ) );
            $_;
        }
        grep {
            defined and $_->{offset} == $offset
        }
        map {
            my $offset;
            try {
                $offset = DateTime::TimeZone->new( name => $_ )->offset_for_datetime($dt);
            }
            catch ($e) {}

            if ($offset) {
                +{
                    %{ $self->olson_zones->{$_} },
                    offset => $offset,
                }
            }
            else {
                undef;
            }
        }
        keys %{ $self->olson_zones };

    return unless ($time_zone);
    return $time_zone->{timezone_name};
}

sub format_offset ( $self, $offset = 0 ) {
    my $hours   = int( abs($offset) / 60 / 60 );
    my $minutes = int( ( abs($offset) - $hours * 60 * 60 ) / 60 );

    return ( $hours + $minutes == 0 )
        ? 'Z'
        : sprintf( '%1s%02d:%02d', ( ( $offset > 0 ) ? '+' : '-' ), $hours, $minutes );
};

sub parse ( $self, $time = undef, $time_zone = 'UTC' ) {
    try {
        $time_zone = DateTime::TimeZone->new( name => $time_zone );
        die unless ( $time_zone->is_olson or $time_zone->is_utc );
    }
    catch ($e) {
        croak('failed to match time zone input to Olson name');
    }

    my $dt;

    if (
        not defined $time or
        $time =~ /^\d+(?:\.\d+)?$/ or
        grep { lc $time eq $_ } qw( now time date datetime )
    ) {
        $time = ( $self->hires ) ? gettimeofday() : time()
            unless ( $time =~ /^\d+(?:\.\d+)?$/ );

        my $nanosecond = $time - int($time);
        $time = int($time);

        $dt = DateTime->from_epoch(
            epoch     => $time,
            time_zone => $time_zone,
        );
        $dt->add( nanoseconds => int( $nanosecond * 1_000_000_000 ) );
    }
    else {
        try {
            my $check_tz_imprecision = sub ( $time, $tz ) {
                my ( $second, $minute, $hour, $day, $month, $year, $offset, $century ) = strptime($time);
                my ( $gm_second, $gm_minute, $gm_hour, $gm_day, $gm_month, $gm_year ) = gmtime;
                my $zones = {
                    P => 'America/Los_Angeles',
                    M => 'America/Denver',
                    C => 'America/Chicago',
                    E => 'America/New_York',
                };

                my $tzdt = DateTime->new(
                    second     => int( $second // 0 ),
                    minute     => $minute // 0,
                    hour       => $hour   // 0,
                    day        => $day,
                    month      => ( $month // $gm_month ) + 1,
                    year       => ( $year // $gm_year ) + 1900,
                    time_zone  => DateTime::TimeZone->new( name => $zones->{ uc($tz) } ),
                );

                return ( $tzdt->is_dst ) ? uc($tz) . 'DT' : uc($tz) . 'ST';
            };
            $time =~ s/\b([PMCE])[SD]T\b/$check_tz_imprecision->( $time, $1 )/ei;
        }
        catch ($e) {
            croak('failed to parse time input')
        }

        my ( $second, $minute, $hour, $day, $month, $year, $offset, $century ) = strptime($time);
        croak('failed to parse time input') unless ($day);

        $second //= 0;
        my $nanosecond = $second - int($second);
        $second = int($second);

        if ( not defined $offset and $time_zone->name ne 'UTC' ) {
            my ( $gm_second, $gm_minute, $gm_hour, $gm_day, $gm_month, $gm_year ) = gmtime;

            try {
                $dt = DateTime->new(
                    nanosecond => int( $nanosecond * 1_000_000_000 ),
                    second     => $second // 0,
                    minute     => $minute // 0,
                    hour       => $hour   // 0,
                    day        => $day,
                    month      => ( $month // $gm_month ) + 1,
                    year       => ( $year // $gm_year ) + 1900,
                    time_zone  => $time_zone->name,
                );
            }
            catch ($e) {
                croak('failed to parse time input')
            }
        }
        else {
            $dt = DateTime->from_epoch( epoch => str2time( $time, 'UTC' ) );
            $dt->add( nanoseconds => $nanosecond );
        }

        $dt->set_time_zone( ( defined $offset ) ? $self->format_offset($offset) : $time_zone->name );

        $dt->set_time_zone( $self->olson( $offset, $dt ) )
            unless ( $dt->time_zone->is_olson or $dt->time_zone->is_utc );
    }

    return $dt;
}

sub canonical ( $self, $dt ) {
    return $dt->strftime('%Y-%m-%dT%T.%3N') . $self->format_offset( $dt->offset );
}

sub validate ( $self, $time = undef, $time_zone = 'UTC' ) {
    my $dt = $self->parse( $time, $time_zone );
    return $self->canonical($dt), $dt->time_zone->name;
}

1;

=head1 NAME

Omniframe::Class::Time

=head1 SYNOPSIS

    use exact;
    use Omniframe::Class::Time;

    my $time = Omniframe::Class::Time->new;

    # print something like "2020-05-06 18:02:31"
    say $time->datetime; # defaults to using time()

    # print something like "2020-05-06 18:02:31"
    say $time->datetime('ansi');

    # print something like "May  6 18:02:31 2020"
    say $time->datetime('log');

    # print something like "06/May/2020:18:02:31 -0700"
    say $time->datetime('common');

    # print something like "05/06/20 18:02:31"
    say $time->datetime( \'%c' );

    # provide a specific time instead of relying on time() internally
    say $time->datetime( 'log', 1588813351 );

    say $time->datetime( 'log', 1588813351, 'PST' );
    say $time->datetime( 'log', '05/06/20 18:02:31', 'PST' );

    # print something like "2020-05-07T01:02:31.157612Z"
    say $time->zulu; # defaults to using time()
    say $time->zulu(1588813351.157612);

    # print something like "2020-05-07T01:02:31Z"
    $time->hires(0);
    say $time->zulu(1588813351.157612);

    say $time->zulu('2020-05-06 18:02:31');
    say $time->zulu('2020-05-06 18:02:31 PST');
    say $time->zulu( '2020-05-06 18:02:31', 'PST' );

    my $zones_1 = $time->zones;
    my $zones_2 = $time->zones(time);

    my $olson_name_1 = $time->olson(-18000);
    my $olson_name_2 = $time->olson( -18000, time );

    my $formatted_offset = $time->format_offset(-18000);

    my $dt = $time->parse( '3/3/2021 3:14pm EST', 'America/Los_Angeles' );

    my $string = $time->canonical($dt);

    my ( $canonical_date_time, $olson_time_zone ) =
        $time->validate( '3/3/2021 3:14pm EST', 'America/Los_Angeles' );

=head1 DESCRIPTION

This class provides methods for handling date/time parsing and canonicalization
of date/time output. It also handles Olson time zone identification from "fuzzy"
time zones. For example, it can determine that "EST" is "America/New_York".

Ideally, it's best to pick up an accurate Olson time zone. From a web browser,
this can be done in Javascript with:

    Intl.DateTimeFormat().resolvedOptions().timeZone;

From Linux, this can be done from the command line with:

    timedatectl

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

=head2 olson_zones

This attribute will generate and contain upon first access a hashref with keys
being every valid Olson time zone. The value of each key will be a hashref with
keys of C<timezone_name> (which is the same as the key), C<olson_description>,
C<location_coords> (as found in an Olson database), and C<population>, which is
the population of the country in which the time zone exists.

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

You can also pass an epoch to use instead of having C<datetime> internally call
C<time>.

    $time->datetime( 'log', 1588813351 );

It's possible also to provide a third, optional parameter to suggest a time zone
if one is not in the time input string (or if you provide an epoch integer).

    $time->datetime( 'log', 1588813351, 'PST' );
    $time->datetime( 'log', '05/06/20 18:02:31', 'PST' );

=head2 zulu

This method prints a Javascript-consumable date/time string corrected to the
Zulu time zone:

    2020-05-07T01:02:31.157612Z

It can optionally accept an epoch. If no epoch is provided, it will assume now.

    say $time->zulu;
    say $time->zulu(1588813351.157612);

By default, this will include microseconds, but this can be switched off by
setting C<hires> to a false value.

=head2 zones

This method accepts an epoch (or will use now if none is provided). It
will return an arrayref of hashrefs, with each hashref representing an Olson
time zone.

    my $zones_1 = $time->zones;
    my $zones_2 = $time->zones(time);

The keys of these hashrefs are:

    {
        name          => '', # Olson time zone name
        name_parts    => [], # Olson time zone name components
        description   => '', # Olson time zone description
        offset        => 0,  # Offset in seconds from UTC
        offset_string => '', # Offset string
        label         => '', # Label for user interfaces
    }

The arrayref will be sorted by offset and name.

=head2 olson

This method requires an an offset in inteter form representing the offset in
seconds from UTC. It optionally accepts an epoch timestamp, and if that's not
provided, it'll assume now.

Based on this, it will determine the most probable time zone and return its
Olson name.

    my $olson_name_1 = $time->olson(-18000);
    my $olson_name_2 = $time->olson( -18000, time );

It does this by finding all time zone that would render the offset, then
selecting the most probable based on country population size and simplicity of
the Olson name.

=head2 format_offset

This method accepts an offset as an integer representing the seconds offset
from UTC. It will return a time zone offset in the form "[+-]HH:MM" for all
non-UTC zones and "Z" for UTC.

    my $formatted_offset = $time->format_offset(-18000);

=head2 parse

This method requires a scalar containing some representation of a date/time.
Typically, this is a string that looks like a date/time, but it could also be
an epoch or the string "now", "time", "date", or "datetime" to mean the current
date/time.

The method can optionally be given an additional string with an Olson name.

The method will return a L<DateTime> object set to the right time and Olson
time zone.

    my $dt = $time->parse( '3/3/2021 3:14pm EST', 'America/Los_Angeles' );

An exception will be thrown if the Olson name input is neither a valid Olson
name nor C<undef>. The date/time string will be parsed, and if it contains a
timezone, that will be used; otherwise, the Olson name provided will be used.

=head2 canonical

This method requires a L<DateTime> object. It will return a canonical string for
that date/time.

    my $string = $time->canonical($dt);

Zulu times will be represented with a "Z", and non-Zulu times will be
represented with an offset in the form "[+-]HH:MM". Seconds can have
microseconds if that data is provided in the epoch input.

=head2 validate

This method accepts the same inputs as C<parse> and will return a string like
what would be returned from C<canonical> plus a valid Olson time zone name.

    my ( $canonical_date_time, $olson_time_zone ) =
        $time->validate( '3/3/2021 3:14pm EST', 'America/Los_Angeles' );

Internally, this method calls C<parse> and C<canonical>.

=head1 WITH ROLES

L<Omniframe::Role::Conf>.

=head1 INHERITANCE

L<Omniframe>.
