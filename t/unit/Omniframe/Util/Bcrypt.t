use Test2::V0;
use exact -conf;
use Omniframe::Util::Bcrypt 'bcrypt';

imported_ok('bcrypt');
like( bcrypt('input'), qr/^[0-9a-f]{46}$/, 'length and consistency' );
done_testing;
