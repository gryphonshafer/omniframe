use Test::Most;
use exact;

my $obj;
use_ok('Omniframe');
lives_ok( sub { $obj = Omniframe->new->with_roles('+Template') }, q{new->with_roles('+Template')} );
ok( $obj->does("Omniframe::Role::$_"), "does $_ role" ) for ( qw( Conf Template ) );
can_ok( $obj, qw( version tt tt_settings ) );

my $tt_conf = $obj->conf->get('template') || {};
$tt_conf->{web} ||= {};
$tt_conf->{web}{wrapper} = undef;
$obj->conf->put( template => $tt_conf );

is(
    $obj->tt_settings->{config}{CONSTANTS}{version},
    $obj->version,
    'tt_settings() return contains object version',
);

my $tt;
lives_ok( sub { $tt = $obj->tt }, 'tt() executes' );
is( ref $tt, 'Template', 'tt() returns Template' );

is(
    $obj->version,
    $obj->tt->context->{CONFIG}{CONSTANTS}{version},
    'tt() Template context contains version',
);

my $output;
lives_ok(
    sub {
        $obj->tt->process(
            \q{
                BEGIN TEST DATA BLOCK
                [% name | ucfirst %]
                [% pi | round %]
                [% constants.version %]
                [% time %]
                [% rand %]
                [% rand( 9 ) %]
                [% rand( 9, 1 ) %]
                [% pick( 'a', 'b' ) %]
                [% text.lower %]
                [% text.upper %]
                [% text.ucfirst %]
                [% value.commify %]
                [% thing.ref %]
                END TEST DATA BLOCK
            },
            {
                name  => 'omniframe',
                pi    => 3.1415,
                value => 123456789,
                text  => 'mIxEd',
                thing => [],
            },
            \$output,
        ) or die $obj->tt->error;
    },
    'process()',
);

like( $output, qr/
    BEGIN\sTEST\sDATA\sBLOCK\s+
    Omniframe\s+
    3\s+
    \d{10}\s+
    \d{10}\s+
    \d\s+
    \d\s+
    \d\s+
    [a|b]\s+
    mixed\s+
    MIXED\s+
    Mixed\s+
    123,456,789\s+
    ARRAY\s+
    END\sTEST\sDATA\sBLOCK
/x, 'template test data block' );

done_testing();
