use Test2::V0;
use exact -conf;
use Project::Control;

my $mock = mock 'Project::Control' => (
    override => [ qw( setup_access_log debug info notice warning warn ) ],
);

my $obj;
ok( lives { $obj = Project::Control->new }, 'new' ) or note $@;
isa_ok( $obj, $_ ) for ( 'Mojolicious', 'Omniframe::Control' );
can_ok( $obj, 'startup' );

done_testing;
