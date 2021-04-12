use Test2::V0;
use Omniframe::Class::Time;

my $obj;
ok( lives { $obj = Omniframe::Class::Time->new }, 'new' ) or note $@;
isa_ok( $obj, $_ ) for ( qw( Omniframe::Class::Time Omniframe ) );
can_ok( $obj, qw(
    hires formats olson_zones
    datetime zulu zones olson format_offset parse canonical
) );

like( $obj->datetime, qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, 'datetime' );

like(
    $obj->datetime( undef, 1588813351 ),
    qr|2020-05-0\d \d{2}:\d{2}:\d{2}|,
    'datetime( undef, time )',
);
like(
    $obj->datetime( 'ansi', 1588813351 ),
    qr|2020-05-0\d \d{2}:\d{2}:\d{2}|,
    q{datetime('ansi')},
);
like(
    $obj->datetime( 'log', 1588813351 ),
    qr|May  \d \d{2}:\d{2}:\d{2} 2020|,
    q{datetime('log')},
);
like(
    $obj->datetime( 'common', 1588813351 ),
    qr|0\d/May/2020:\d{2}:\d{2}:\d{2} [+-]\d{4}|,
    q{datetime('common')},
);
like(
    $obj->datetime( \'%c', 1588813351 ),
    qr|05/0\d/20 \d{2}:\d{2}:\d{2}|,
    q{datetime( time, 'access' )},
);

like( $obj->zulu, qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z/, 'zulu' );
is( $obj->zulu(1588813351.100764), '2020-05-07T01:02:31.100764Z', 'zulu(time)' );

$obj->hires(0);
like( $obj->zulu, qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/, 'zulu no hires' );
is( $obj->zulu(1588813351.100764), '2020-05-07T01:02:31Z', 'zulu(time) no hires' );

my $zones = $obj->zones;
my ($ptz) = grep { $_->{name} eq 'America/Los_Angeles' } @$zones;

is( scalar(@$zones), 424, 'zones count' );
like(
    $ptz,
    {
        description   => 'Pacific',
        label         => qr/\(GMT-0[78]:00\) America - Los Angeles \[Pacific\]/,
        name          => 'America/Los_Angeles',
        name_parts    => [ 'America', 'Los Angeles' ],
        offset        => qr/-2(?:52|88)00/,
        offset_string => qr/\-0[78]:00/,
    },
    'Pacific time zone',
);
like( $obj->olson(-18000), qr\America/(?:Chicago|New_York)\, 'olson(-18000)' );
is( $obj->format_offset(-18000), '-05:00', 'format_offset(-18000)' );

for (
    [
        [ '2020-03-04T01:02:31.1234Z' ],
        [ '2020-03-04T01:02:31.123Z', 'UTC' ],
    ],
    [
        [ '2020-03-04 01:02:31.1234' ],
        [ '2020-03-04T01:02:31.123Z', 'UTC' ],
    ],
    [
        [ '2020-03-04 01:02:31.1234 EST' ],
        [ '2020-03-04T01:02:31.123-05:00', 'America/New_York' ],
    ],
    [
        [ '2020-03-04 01:02:31.1234 GMT+7' ],
        [ '2020-03-04T01:02:31.123+07:00', 'Asia/Jakarta' ],
    ],
    [
        [ '2020-03-04 01:02:31.1234 PST' ],
        [ '2020-03-04T01:02:31.123-08:00', 'America/Los_Angeles' ],
    ],
    [
        [ '2020-03-04 01:02:31.1234', 'America/Los_Angeles' ],
        [ '2020-03-04T01:02:31.123-08:00', 'America/Los_Angeles' ],
    ],
    [
        [ '2020-03-04T01:02:31.1234Z', 'America/Los_Angeles' ],
        [ '2020-03-04T01:02:31.123Z', 'UTC' ],
    ],
    [
        [ '2020-03-04 01:02:31.1234 EST', 'America/Los_Angeles' ],
        [ '2020-03-04T01:02:31.123-05:00', 'America/New_York' ],
    ],
    [
        [ '3/3 01:02:31.1234', 'America/Los_Angeles' ],
        [ '2021-03-03T01:02:31.000-08:00', 'America/Los_Angeles' ],
    ],
    [
        [ '2021-02-12 01:02:31.1234 EST' ],
        [ '2021-02-12T01:02:31.123-05:00', 'America/New_York' ],
    ],
    [
        [ '2021-02-12 01:02:31.1234 EDT' ],
        [ '2021-02-12T01:02:31.123-05:00', 'America/New_York' ],
    ],
    [
        [ '2021-07-17 01:02:31.1234 EST' ],
        [ '2021-07-17T01:02:31.123-04:00', 'America/New_York' ],
    ],
    [
        [ '2021-07-17 01:02:31.1234 EDT' ],
        [ '2021-07-17T01:02:31.123-04:00', 'America/New_York' ],
    ],
    [
        [ '3/3/2021 3:14pm EST', 'America/Los_Angeles' ],
        [ '2021-03-03T15:14:00.000-05:00', 'America/New_York' ],
    ],
    [
        [ '2021-03-04' ],
        [ '2021-03-04T00:00:00.000Z', 'UTC' ],
    ],
) {
    my $dt = $obj->parse( @{ $_->[0] } );

    is(
        [
            $obj->canonical($dt),
            $dt->time_zone->name,
        ],
        $_->[1],
        'canonical: ' . join( ' + ', @{ $_->[0] } ),
    );

    is(
        [ $obj->validate( @{ $_->[0] } ) ],
        $_->[1],
        'validate: ' . join( ' + ', @{ $_->[0] } ),
    );
}

done_testing;
