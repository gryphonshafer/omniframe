use Test2::V0;
use exact;
use Omniframe::Class::Javascript;

my $obj;
ok( lives { $obj = Omniframe::Class::Javascript->new }, 'new' ) or note $@;
isa_ok( $obj, $_ ) for ( qw( Omniframe::Class::Javascript Omniframe ) );
can_ok( $obj, qw( setup teardown run ) );

is(
    $obj->run(
        'OCJS.out( OCJS.in.answer * 2 )',
        { answer => 42 },
    ),
    [[84]],
    'run',
);

done_testing;
