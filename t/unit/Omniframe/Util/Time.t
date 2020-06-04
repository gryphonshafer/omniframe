use Test::Most;
use exact;

my $obj;
use_ok('Omniframe::Util::Time');
lives_ok( sub { $obj = Omniframe::Util::Time->new }, 'new' );
isa_ok( $obj, $_ ) for ( qw( Omniframe::Util::Time Omniframe ) );
can_ok( $obj, qw( datetime ) );

like( $obj->datetime, qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, 'datetime' );

is( $obj->datetime( undef,    1588813351 ), '2020-05-06 18:02:31',        'datetime( undef, time )'     );
is( $obj->datetime( 'ansi',   1588813351 ), '2020-05-06 18:02:31',        q{datetime('ansi')}           );
is( $obj->datetime( 'log',    1588813351 ), 'May  6 18:02:31 2020',       q{datetime('log')}            );
is( $obj->datetime( 'common', 1588813351 ), '06/May/2020:18:02:31 -0700', q{datetime('common')}         );
is( $obj->datetime( \'%c',    1588813351 ), '05/06/20 18:02:31',          q{datetime( time, 'access' )} );

like( $obj->zulu, qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/, 'zulu' );
is( $obj->zulu(1588813351), '2020-05-07T01:02:31Z', 'zulu(time)' );

done_testing();
