use Test2::V0;
use exact -conf;
use Omniframe::Mojo::DevDocs;

my $obj;
ok( lives { $obj = Omniframe::Mojo::DevDocs->new }, 'new' ) or note $@;
can_ok( $obj, 'setup' );

done_testing;
