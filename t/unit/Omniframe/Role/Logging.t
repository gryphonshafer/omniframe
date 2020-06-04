use Test::Most;
use Test::Output;
use exact;

use_ok($_) for ( qw(
    Omniframe
    Email::Mailer
    Log::Dispatch::Email::Mailer
) );

my $obj;
lives_ok( sub { $obj = Omniframe->new->with_roles('+Logging') }, q{new->with_roles('+Logging')} );
ok( $obj->does("Omniframe::Role::$_"), "does $_ role" ) for ( qw( Conf Logging ) );
can_ok( $obj, qw(
    log_file log_level log_levels log_dispatch dp
    debug info notice warning warn error err critical crit alert emergency emerg
) );

$obj->conf->put( 'logging', 'filter', [ 'log_file', 'email' ] );

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

done_testing();
