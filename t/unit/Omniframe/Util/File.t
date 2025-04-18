use Test2::V0;
use exact -conf;
use Omniframe::Util::File 'opath';

imported_ok('opath');

my $path;

ok( lives { $path = opath( qw( lib Omniframe Util File.pm ) ) }, 'good file' ) or note $@;
isa_ok( $path, 'Mojo::File' );
ok( -r $path, 'file readable' );

ok( lives { $path = opath( 'file/does/not/exist', { no_check => 1 } ) }, 'bad file + no check' ) or note $@;
isa_ok( $path, 'Mojo::File' );
ok( ! -r $path, 'file unreadable' );

like(
    dies { opath('file/does/not/exist') },
    qr|File does not exist or is not readable: "file/does/not/exist"|,
    'bad file',
);

done_testing;
