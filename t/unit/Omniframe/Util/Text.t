use Test2::V0;
use Omniframe::Util::Text qw( deat trim );

imported_ok( qw( deat trim ) );

is( deat('Something bad happened at /some/place.pl line 42.'), 'Something bad happened', 'deat' );
is( trim(' Stuff   and things '), 'Stuff and things', 'trim' );

done_testing;
