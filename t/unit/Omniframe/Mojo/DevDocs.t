use Test2::V0;
use Omniframe::Mojo::DevDocs;

my $obj;
ok( lives { $obj = Omniframe::Mojo::DevDocs->new }, 'new' ) or note $@;
can_ok( $obj, 'setup' );
DOES_ok( $obj, 'Omniframe::Role::Conf' );

done_testing;
