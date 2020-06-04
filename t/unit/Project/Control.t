use Test::Most;
use exact;

my $obj;
use_ok('Project::Control');
lives_ok( sub { $obj = Project::Control->new }, 'new()' );
isa_ok( $obj, $_ ) for ( 'Mojolicious', 'Omniframe::Control' );
can_ok( $obj, 'startup' );

done_testing();
