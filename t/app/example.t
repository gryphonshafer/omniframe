use Test::Most;
use Test::Mojo;
use Test::MockModule;
use exact -conf;

$ENV{MOJO_LOG_LEVEL} = 'error';
my $mock = Test::MockModule->new('Omniframe::Control');
$mock->redefine( $_, 1 ) for ( qw( setup_access_log debug info notice warning warn ) );

my $t = Test::Mojo->new('Omniframe::Control');

my ( $home_page, $page_unexplicit ) =
    map { $t->get_ok($_) } ( '/', '/not/an/explicitly/defined/path/in/router/table' );

$_
    ->status_is(200)
    ->header_is( 'content-type' => 'text/html;charset=UTF-8' )
    ->text_is( title => 'Example Page' )
for ( $home_page, $page_unexplicit );

$home_page
    ->text_is( h1 => 'Example Page' )
    ->attr_like( 'link[rel="stylesheet"]:last-of-type', 'href', qr|\bapp.css\?version=\d+| )
    ->tx->res->dom->find('span.copy')->each( sub {
        is( $_->text, "\xa9", 'copy content' );
    } );

done_testing();
