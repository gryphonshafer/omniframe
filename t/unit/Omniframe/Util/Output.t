use Test2::V0;
use exact -conf;
use Omniframe::Util::Output qw( dp table trim );

imported_ok( qw( dp table trim ) );

my @dp = dp( [ { answer => 42 } ] );
is( @dp, 1, 'dp results count');
like( $dp[0], qr/
    \n
    \e\[0;38;5;81m\{\e\[m\n[ ]*
    [ ]*\e\[0;38;5;104manswer\e\[m\e\[0;38;5;81m[ ]*\e\[m\e\[0;38;
    5;209m42\e\[m\n
    \e\[0;38;5;81m\}\e\[m\n
/x, 'dp content' );

like( dies { table() },               qr/\binput missing or malformed\b/, 'input missing'   );
like( dies { table( 1, 2, 3 ) },      qr/\binput missing or malformed\b/, 'input malformed' );
like( dies { table( answer => 42 ) }, qr/\btable requires rows data\b/,   'no rows data'    );

is(
    table( [ [ 1, 2, 3 ], [ 4, 5, 6 ] ] ),
    join( "\n",
        '| 1 | 2 | 3 |',
        '| 4 | 5 | 6 |',
    ),
    'simple table no header',
);

is(
    table( [
        { alpha => 1, bravo => 2, charlie_delta => 'Stuff and Things' },
        { alpha => 4, bravo => 5, charlie_delta => 'Things and Stuff and More' },
    ] ),
    join( "\n",
        '| Alpha | Bravo | Charlie Delta             |',
        '|------:|------:|---------------------------|',
        '|     1 |     2 | Stuff and Things          |',
        '|     4 |     5 | Things and Stuff and More |',
    ),
    'table with header',
);

is(
    table(
        rows => [
            { thing => 'Thing 1',  x => 2048, stuff_things => 'Stuff',  user_id => 1138 },
            { thing => 'Thing 16', x =>   16, stuff_things => 'Things', user_id => 1024 },
        ],
        cols => [
            'user_id',               # becomes "User ID" aligned right due to data
            [ 'thing', 'Things' ],   # becomes "Things" aligned left
            [ 'stuff_things', 'r' ], # becomes "Stuff Things" aligned right explicitly
            [ 'x', 'c', 'Name' ],    # becomes "Name" aligned center explicitly
        ],
    ),
    join( "\n",
        '| User ID | Things   | Stuff Things | Name |',
        '|--------:|----------|-------------:|:----:|',
        '|    1138 | Thing 1  |        Stuff | 2048 |',
        '|    1024 | Thing 16 |       Things |  16  |',
    ),
    'table with header and defined columns',
);

is( trim(' Stuff   and things '), 'Stuff and things', 'trim' );

done_testing;
