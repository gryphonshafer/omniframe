use Test::Most;
use Test::Synopsis;
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
                synopsis_ok($_);
            }
        },
    },
    'lib',
);

chdir($cwd);
done_testing();
