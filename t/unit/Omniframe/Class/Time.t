use Test2::V0;
use exact;
use Omniframe::Class::Time;

my $time;
ok( lives { $time = Omniframe::Class::Time->new( time_zone => 'UTC' ) }, 'new' ) or note $@;
isa_ok( $time, $_ ) for ( qw( Omniframe::Class::Time Omniframe ) );
can_ok( $time, qw(
    time_zone locale datetime formats olson_zones
    set format split parse olson
) );

ok( lives { $time->set(1689093000.12345) }, 'set' ) or note $@;

is( $time->format('ansi'), '2023-07-11 16:30:00', 'ansi' );
is( $time->format('sqlite'), '2023-07-11 16:30:00.123+00:00', 'sqlite' );
is( $time->format('sqlite_min'), '2023-07-11 16:30+00:00', 'sqlite_min' );
is( $time->format('%a, %d %b %Y %H:%M:%S %z'), 'Tue, 11 Jul 2023 16:30:00 +0000', 'strftime' );

is( $time->split('Tue Jul 11 09:30:00 2023'), {
    second => '00',
    minute => 30,
    hour   => '09',
    day    => 11,
    month  => 7,
    year   => 2023,
    offset => undef,
}, 'split' );

is( $time->parse('Tue Jul 11 09:30:00 2023 PDT')->format('ansi'), '2023-07-11 09:30:00', 'parse' );

like( $time->olson(-18000), qr\America/(?:Chicago|New_York)\, 'olson(-18000)' );

is(
    $time->parse('Dec 20 15:56:33.123 2023 -08:00')->olsonize->datetime->time_zone->name,
    'America/Los_Angeles',
    'olsonize',
);

done_testing;
