use Test2::V0;
use exact -conf;
use Omniframe::Mojo::Document;

my $mock = mock 'Omniframe::Mojo::Document' => ( override => 'notice' );

my $obj;
ok( lives { $obj = Omniframe::Mojo::Document->new }, 'new' ) or note $@;
can_ok( $obj, qw( document_helper docs_nav_helper ) );
DOES_ok( $obj, 'Omniframe::Role::Logging' );

for my $name ( qw( document_helper docs_nav_helper ) ) {
    my $helper;
    ok( lives { $helper = $obj->$name }, $name ) or note $@;
    ref_ok( $helper, 'CODE', 'helper set' );
}

done_testing;
