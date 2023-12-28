use Test2::V0;
use Omniframe::Util::Text 'trim';

imported_ok('trim');
is( trim(' Stuff   and things '), 'Stuff and things', 'trim' );

done_testing;
