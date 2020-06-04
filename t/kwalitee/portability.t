use Test::Portability::Files;
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

exact->monkey_patch( 'Test::Portability::Files', maniread => sub {
    my @files;

    find(
        {
            no_chdir => 1,
            wanted   => sub {
                if ( -f $_ and -T $_ and not $matcher->($_) ) {
                    push( @files, $File::Find::name );
                }
            },
        },
        '.',
    );

    return { map { $_ => 1 } @files };
} );

options(
    test_amiga_length     => 1,
    test_ansi_chars       => 1,
    test_case             => 1,
    test_dos_length       => 0,
    test_mac_length       => 0,
    test_one_dot          => 0,
    test_space            => 1,
    test_special_chars    => 1,
    test_symlink          => 1,
    test_vms_length       => 1,
    test_windows_reserved => 1,
);

run_tests();
chdir($cwd);
