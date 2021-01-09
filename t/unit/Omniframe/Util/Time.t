use Test2::V0;
use exact -conf;
use Omniframe::Util::Time;

my $obj;
ok( lives { $obj = Omniframe::Util::Time->new }, 'new' ) or note $@;
isa_ok( $obj, $_ ) for ( qw( Omniframe::Util::Time Omniframe ) );
can_ok( $obj, qw( datetime ) );

like( $obj->datetime, qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, 'datetime' );

like(
    $obj->datetime( undef,    1588813351 ),
    qr|2020-05-0\d \d{2}:\d{2}:\d{2}|,
    'datetime( undef, time )',
);
like(
    $obj->datetime( 'ansi',   1588813351 ),
    qr|2020-05-0\d \d{2}:\d{2}:\d{2}|,
    q{datetime('ansi')},
);
like(
    $obj->datetime( 'log',    1588813351 ),
    qr|May  \d \d{2}:\d{2}:\d{2} 2020|,
    q{datetime('log')},
);
like(
    $obj->datetime( 'common', 1588813351 ),
    qr|0\d/May/2020:\d{2}:\d{2}:\d{2} [+-]\d{4}|,
    q{datetime('common')},
);
like(
    $obj->datetime( \'%c',    1588813351 ),
    qr|05/0\d/20 \d{2}:\d{2}:\d{2}|,
    q{datetime( time, 'access' )},
);

like( $obj->zulu, qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z/, 'zulu' );
is( $obj->zulu(1588813351.100764), '2020-05-07T01:02:31.100764Z', 'zulu(time)' );

$obj->hires(0);
like( $obj->zulu, qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/, 'zulu no hires' );
is( $obj->zulu(1588813351.100764), '2020-05-07T01:02:31Z', 'zulu(time) no hires' );

done_testing;
