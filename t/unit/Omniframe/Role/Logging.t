use Test2::V0;
use Test::Output;
use exact -conf;
use Omniframe;

my $obj;
ok( lives { $obj = Omniframe->with_roles('+Logging')->new }, q{with_roles('+Logging')->new} ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Logging' );
can_ok( $obj, qw(
    log_file log_level log_levels log_dispatch
    debug info notice warning warn error err critical crit alert emergency emerg
) );

conf->put( 'logging', 'filter', [ 'log_file', 'email' ] );

output_like(
    sub {
        my $level = $_->[0];
        $obj->$level('Test-generated message');
    },
    $_->[1][0],
    $_->[1][1],
    "test-generated $_->[0] message looks proper",
) for (
    map {
        my $qr = qr/\w{3}\s+\d+\s+\d+:\d+:\d+\s+\d{4}\s+\[$_->[2]\]\s+Test-generated message/;
        $_->[1] = ( $_->[1] ) ? [ undef, $qr ] : [ $qr, undef ];
        $_;
    }
    (
        [ 'debug',     0, 'DEBUG'     ],
        [ 'info',      0, 'INFO'      ],
        [ 'notice',    0, 'NOTICE'    ],
        [ 'warning',   1, 'WARNING'   ],
        [ 'warn',      1, 'WARNING'   ],
        [ 'error',     1, 'ERROR'     ],
        [ 'err',       1, 'ERROR'     ],
        [ 'critical',  1, 'CRITICAL'  ],
        [ 'crit',      1, 'CRITICAL'  ],
        [ 'alert',     1, 'ALERT'     ],
        [ 'emergency', 1, 'EMERGENCY' ],
        [ 'emerg',     1, 'EMERGENCY' ],
    )
);

done_testing;
