package Omniframe::Class::Javascript;

use exact 'Omniframe';
use JavaScript::QuickJS;
use Mojo::File qw( path tempdir );
use Mojo::JSON 'encode_json';

with 'Omniframe::Role::Output';

has basepath  => undef;
has importmap => undef;
has tempdir   => undef;
has mapping   => {};

sub new ( $self, @params ) {
    $self = $self->SUPER::new(@params);
    $self->setup;
    return $self;
}

sub DESTROY ($self) {
    $self->teardown;
}

sub setup ( $self, $basepath = $self->basepath, $importmap = $self->importmap ) {
    return $self unless ($importmap);

    $self->tempdir(tempdir);

    while ( my ( $name, $value ) = each $importmap->%* ) {
        $self->mapping->{$name}{source} = path( ( ($basepath) ? $basepath . '/' : '' ) . $value . '.js' );
        $self->mapping->{$name}{target} = $self->tempdir->child( $value . '.js' );
    }

    for ( values $self->mapping->%* ) {
        $_->{target}->dirname->make_path;
        $_->{target}->spew(
            $self->_import_re(
                $_->{source}->slurp,
            )
        );
    }

    return $self;
}

sub teardown ($self) {
    $self->tempdir->remove_tree if ( $self->tempdir );
    return $self;
}

sub run ( $self, $module, $in = undef ) {
    my $output;

    $module = path($module)->slurp if ( -f $module );
    $module = $self->_import_re($module) if ( $self->mapping->%* );
    $module =~ s/^\s*(?!import\b)/\nOCJS.in = JSON.parse( OCJS.in );\n/im;

    my $js = JavaScript::QuickJS
        ->new
        ->set_globals(
            OCJS => {
                in  => encode_json($in),
                out => sub { push( @$output, \@_ ) },
            },
        );

    try {
        $js->eval_module($module);
        $js->await;
    }
    catch ($e) {
        $e = deat $e;
        chomp $e;
        croak( 'OCJS eval error: { ' . $e . ' }' );
    }

    return $output;
}

sub _import_re ( $self, $js, $cb = sub {} ) {
    my $_import_remap = sub ( $pre, $from, $post ) {
        my $quote = substr( $from, 0, 1 );
        $from = substr( $from, 1, length($from) - 2 );
        return $pre . $quote . $self->mapping->{$from}{target}->to_string . $quote . $post;
    };

    $js =~ s/^(\s*import\b[^;]*?)("[^"]+"|'[^']+')(\s*;)/ $_import_remap->( $1, $2, $3 ) /imge;
    return $js;
};

1;

=head1 NAME

Omniframe::Class::Javascript

=head1 SYNOPSIS

    use exact;
    use Omniframe::Class::Javascript;

    my $js = Omniframe::Class::Javascript->new(
        basepath  => '../project/static/js/',
        importmap => {
            'modules/distribution' => 'path/to/modules/distribution/file',
        },
    );

    my $output_0 = $js->run( 'test.js', { value => 3 } );
    my $output_1 = $js->run(
        q{
            import distribution from 'modules/distribution';
            OCJS.out( distribution( OCJS.in.value ) );
        },
        { value => 3 },
    );

=head1 DESCRIPTION

This class provides the means to execute Javascript via L<JavaScript::QuickJS>.
The class will handle consuming an importmap if provided.

=head1 ATTRIBUTES

=head2 basepath

This optioanl attribute specifies a base path for Javascript files referenced
in the values of the C<importmap> hashref.

=head2 importmap

This optional hashref can contain a Javascript importmap.

=head2 tempdir

This attribute's value is a L<Mojo::File> instance of a temporary directory and
is automatically created during C<new> or C<setup> calls.

=head2 mapping

This hashref is built during C<new> or C<setup> calls based on C<basepath> and
C<importmap> data. Its keys are the same keys of C<importmap>, and its values
are hashrefs with keys of C<source> (a L<Mojo::File> of the source path) and
C<target> (a L<Mojo::File> of the target).

=head1 METHODS

=head2 new

This method internally calls C<setup>.

    my $js = Omniframe::Class::Javascript->new(
        basepath  => '../project/static/js/',
        importmap => {
            'modules/distribution' => 'path/to/modules/distribution/file',
        },
    );

=head2 setup

This method optionally accepts C<basepath> and C<importmap> override data, which
will be a saved to the object and used. The method will then setup everything
necessar to run Javascript via C<run>.

=head2 teardown

This method cleans up everything from C<setup> and is automatically run during
object destruction.

=head2 run

Accepts either a string representing a path to a file of Javascript or
Javascript source itself. Optionally also accepts a hashref of data to be
injected as the C<OCJS.in> value inside the Javascript.

    my $output_0 = $js->run( 'test.js', { value => 3 } );
    my $output_1 = $js->run(
        q{
            import distribution from 'modules/distribution';
            OCJS.out( distribution( OCJS.in.value ) );
        },
        { value => 3 },
    );

Any data in all calls to C<OCJS.out> in the Javascript will be returned as
output from C<run>.

=head1 WITH ROLES

L<Omniframe::Role::Output>.

=head1 INHERITANCE

L<Omniframe>.
