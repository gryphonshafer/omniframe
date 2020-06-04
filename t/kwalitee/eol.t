use Test::Most;
use Test::EOL;
use Cwd 'getcwd';
use File::Find 'find';
use Mojo::File;
use Text::Gitignore 'build_gitignore_matcher';
use exact -conf;

my $root_dir = conf->get( qw( config_app root_dir ) );
my $cwd = getcwd();
chdir($root_dir);

my $matcher = build_gitignore_matcher( [
    '.git', map { s|^/|./|; $_ } split( "\n", Mojo::File->new('.gitignore')->slurp )
] );

find(
    {
        no_chdir => 1,
        wanted   => sub {
            if ( -f $_ and -T $_ and not $matcher->($_) ) {
                eol_unix_ok( $_, { trailing_whitespace => 1 } );
            }
        },
    },
    '.',
);

chdir($cwd);
done_testing();
