package Omniframe::Class::Time;

use exact 'Omniframe';
use Date::Format ();
use Date::Parse ();
use DateTime;
use DateTime::TimeZone;
use DateTime::TimeZone::Olson 'olson_country_selection';
use Time::HiRes ();
use YAML::XS ();

with 'Omniframe::Role::Conf';

has time_zone => 'local';
has locale    => 'en-US';
has datetime  => undef;

class_has formats => {
    ansi    => '%Y-%m-%d %T',
    log     => '%b %e %T %Y',
    common  => '%d/%b/%Y:%T %z',
    rfc822  => '%a, %d %b %Y %H:%M:%S %z',
};

class_has olson_zones => sub ($self) {
    my $olson_zones;
    my $country_population = YAML::XS::LoadFile(
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

sub set ( $self, $epoch = Time::HiRes::time, $time_zone = $self->time_zone ) {
    $epoch = Time::HiRes::time if ( $epoch eq 'now' );

    $self->datetime(
        ( $epoch->isa('DateTime') )
            ? $epoch
            : DateTime->from_epoch(
                epoch     => $epoch,
                time_zone => $time_zone,
            )
    );

    return $self;
}

sub format ( $self, $format = 'ansi' ) {
    return $self->datetime->rfc3339 if ( lc($format) eq 'rfc3339' );
    return $self->datetime->iso8601 if ( lc($format) eq 'iso8601' );

    return $self->datetime->strftime(
        ( lc($format) eq 'sqlite_min' ) ? '%F %H:%M' : '%F %T.%3N'
    ) . (
        ( $self->datetime->time_zone->name eq 'UTC' ) ? '+00:00' : do {
            my $offset  = $self->datetime->offset;
            my $hours   = int( abs($offset) / 60 / 60 );
            my $minutes = int( ( abs($offset) - $hours * 60 * 60 ) / 60 );
            sprintf( '%1s%02d:%02d', ( ( $offset > 0 ) ? '+' : '-' ), $hours, $minutes );
        }
    ) if ( lc($format) eq 'sqlite' or lc($format) eq 'sqlite_min' );

    return $self->datetime->strftime( $self->formats->{ lc $format } // $format );
}

sub split ( $self, $text ) {
    my $parts;
    @$parts{ qw( second minute hour day month year offset ) } = Date::Parse::strptime($text);

    if ( defined $parts->{offset} ) {
        my $hours   = int( abs( $parts->{offset} ) / 60 / 60 );
        my $minutes = int( ( abs( $parts->{offset} ) - $hours * 60 * 60 ) / 60 );

        $parts->{offset} =
            sprintf( '%1s%02d:%02d', ( ( $parts->{offset} > 0 ) ? '+' : '-' ), $hours, $minutes );
    }

    if ( defined $parts->{year} ) {
        $parts->{year} += 100 if ( $parts->{year} < 45 );
        $parts->{year} += 1900;
    }

    $parts->{month}++ if ( defined $parts->{month} );

    if ( $parts->{hour} ) {
        $parts->{year}  = (localtime)[5] + 1900 if ( not defined $parts->{year}  );
        $parts->{month} = (localtime)[4] + 1    if ( not defined $parts->{month} );
        $parts->{day}   = (localtime)[3]        if ( not defined $parts->{day}   );
    }

    return $parts;
}

my $usian_zones = {
    P => 'America/Los_Angeles',
    M => 'America/Denver',
    C => 'America/Chicago',
    E => 'America/New_York',
};

sub parse ( $self, $text ) {
    $text =~ s/\r?\n/ /g;

    my $time_zone;
    $time_zone = $1 while ( $text =~ s/
        \b(
            [A-z_]+\/[A-z_]+ |
            L(?:ocal)        |
            Z(?:ulu)?        |
            ([PMCE])[SD]?T   |
            ([PMCE])(?:acific|ountain|entral|astern)\s*(?:[A-z]+\s+)?(?:Time)?
        )\b
    //gix );
    if ($time_zone) {
        if ( $time_zone =~ /z(?:ulu)?/i ) {
            $time_zone = 'UTC';
        }
        elsif ( $time_zone =~ /\b([PMCE])[DS]?T\b/i ) {
            my $letter = uc($1);
            $time_zone = $usian_zones->{$letter};

            my $parse = $self->split($text);
            delete $parse->{$_} for ( qw( second offset ) );
            $parse->{time_zone} = $time_zone;
            $parse->{locale} //= $self->locale;

            my $is_dst = 0;
            eval {
                $is_dst = DateTime->new(%$parse)->is_dst
            };

            $text .= ' ' . $letter . ( ($is_dst) ? 'D' : 'S' ) . 'T';
        }
    }

    my $parts = $self->split($text);
    $parts->{time_zone} //= $time_zone // $parts->{offset} // $self->time_zone;

    if ( not defined $parts->{year} ) {
        $self->datetime( DateTime->from_epoch(
            maybe time_zone => $parts->{time_zone},
            epoch           => (
                ( $text =~ s/^\s*(\-?\d{5,}(?:[.,]\d+)?)\s*// ) ? $1                :
                ( $text =~ s/^\s*\b(now)\b\s*//i              ) ? Time::HiRes::time :
                    Date::Parse::str2time($text),
            ),
        ) );
    }
    else {
        $parts->{nanosecond} = ( $parts->{second} )
            ? int( ( $parts->{second} - int( $parts->{second} ) ) )
            : undef;
        $parts->{second} = int( $parts->{second} ) if ( $parts->{second} );
        $parts->{nanosecond} = $1 if ( not $parts->{nanosecond} and $text =~ /(\.\d+)/ );
        $parts->{nanosecond} *= 1_000_000_000 if ( $parts->{nanosecond} );

        delete $parts->{offset};
        $parts->{locale} //= $self->locale;
        $parts = { map { $_ => $parts->{$_} } grep { defined $parts->{$_} } keys %$parts };

        $self->datetime( DateTime->new(%$parts) );
    }

    return $self;
}

sub olson ( $self, $offset, $time = Time::HiRes::time ) {
    my $dt = ( $time->isa('DateTime') ) ? $time : DateTime->from_epoch( epoch => $time );
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

sub olsonize ($self) {
    return $self unless (
        $self->datetime and
        not $self->datetime->time_zone->is_olson
    );

    my $olson = $self->olson( $self->datetime->offset, $self->datetime->epoch );
    $self->datetime->set_time_zone($olson) if $olson;

    return $self;
}

1;

=head1 NAME

Omniframe::Class::Time

=head1 SYNOPSIS

    use exact;
    use Omniframe::Class::Time;

    my $time = Omniframe::Class::Time->new;

    # print something like "2020-05-06 18:02:31"
    say $time->set->format('ansi');

    # print something like "2023-12-21 12:48:32.126-08:00"
    say $time->set->format('sqlite');

    # print an RFC822-conformant string
    say $time->set->format('%a, %d %b %Y %H:%M:%S %z');

    # print something like "2023-12-21 20:48:32.126Z"
    $time->set->datetime->set_time_zone('UTC');
    say $time->format('sqlite');

    # hashref of the parts of a time string
    my $parts_hashref = $time->split('Tue Jul 11 09:30:00 2023');

    # parse a time string and format it
    say $time->parse('Tue Jul 11 09:30:00 2023 PDT')->format('ansi');

    my $olson_name_1 = $time->olson(-18000);
    my $olson_name_2 = $time->olson( -18000, time );

    # print "America/Los_Angeles"
    say $time
        ->set('Dec 20 15:56:33.123 2023 -08:00')
        ->olsonize
        ->datetime->time_zone->name;

=head1 DESCRIPTION

This class provides methods for handling date/time parsing and formatting.
It also handles Olson time zone identification from "fuzzy" time zones.
For example, it can determine that "EST" is "America/New_York".

Ideally, it's best to pick up an accurate Olson time zone. From a web browser,
this can be done in Javascript with:

    Intl.DateTimeFormat().resolvedOptions().timeZone;

From Linux, this can be done from the command line with:

    timedatectl

=head1 ATTRIBUTES

=head2 time_zone

This is the default time zone to use when understanding dates/times. If not set
explicitly, it defaults to the local time zone.

=head2 locale

This is the locale to use when understanding dates/times. If not set explicitly,
it defaults to "en-US".

=head2 datetime

This is a container for the last L<DateTime> object created via C<set> or
C<parse>.

=head2 formats

This is a hashref of some C<strftime> formats by name. Note that this attribute
is a class-level attribute.

=head2 olson_zones

This attribute will generate and contain upon first access a hashref with keys
being every valid Olson time zone. The value of each key will be a hashref with
keys of C<timezone_name> (which is the same as the key), C<olson_description>,
C<location_coords> (as found in an Olson database), and C<population>, which is
the population of the country in which the time zone exists.

Note that this attribute is a class-level attribute.

=head1 METHODS

=head2 set

Set a time, likely to run C<format> against. Accepts either an epoch,
L<DateTime> object, or "now" string (and defaults to "now" if not set) plus an
optional time zone to use (which defaults to the class's time zone attribute if
not provided).

Returns the class object.

=head2 format

Given a class object with a C<datetime> attribute set, it will return a
formatted string of the date/time value. This method accepts a C<strftime>
format or a named format (like "ANSI" or "RFC3339" or "ISO8601"). If nothing is
provided, the method will assume the "ANSI" format.

=head2 split

Given a date/time string, this method will attempt to split the string into its
parts and return a hashref of the named parts.

=head2 parse

This method accepts a date/time string and will parse it into a L<DateTime>
object stored in the C<datetime> attribute. It should handle a wide range of
inputs correctly.

Returns the class object.

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

=head2 olsonize

Given a class object where C<datetime> has a L<DateTime> value that itself has
an offset value but no Olson time zone, this method will attempt to use the
C<olson> method to set the time zone of the L<DateTime> object to an Olson time
zone.

=head1 WITH ROLES

L<Omniframe::Role::Conf>.

=head1 INHERITANCE

L<Omniframe>.
