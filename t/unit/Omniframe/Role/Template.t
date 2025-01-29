use Test2::V0;
use exact -conf;
use Omniframe;

my $obj;
ok( lives { $obj = Omniframe->with_roles('+Template')->new }, q{with_roles('+Template')->new} ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Template' );
can_ok( $obj, qw( tt_version tt tt_settings tt_html ) );

my $tt_conf = conf->get('template') || {};
$tt_conf->{web} ||= {};
$tt_conf->{web}{wrapper} = undef;
conf->put( template => $tt_conf );

is(
    $obj->tt_settings->{config}{VARIABLES}{version},
    $obj->tt_version,
    'tt_settings() return contains object version',
);

my $tt;
ok( lives { $tt = $obj->tt }, 'tt() executes' ) or note $@;
is( ref $tt, 'Template', 'tt() returns Template' );

is(
    $obj->tt_version,
    $obj->tt->context->{CONFIG}{VARIABLES}{version},
    'tt() Template context contains version',
);

my $output;
ok(
    lives {
        $obj->tt->process(
            \q{
                BEGIN TEST DATA BLOCK
                [% name | ucfirst %]
                [% pi | round %]
                [% version %]
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
    'process',
) or note $@;

like( $output, qr/
    BEGIN\sTEST\sDATA\sBLOCK\s+
    Omniframe\s+
    3\s+
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

done_testing;
