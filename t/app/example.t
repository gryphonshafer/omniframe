use Test2::V0;
use Test2::MojoX;
use exact -conf;
use Omniframe::Control;

$ENV{MOJO_LOG_LEVEL} = 'error';

my $mock = mock 'Omniframe::Control' => (
    override => [ qw( setup_access_log debug info notice warning warn ) ],
);

my $t = Test2::MojoX->new('Omniframe::Control');

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

done_testing;
