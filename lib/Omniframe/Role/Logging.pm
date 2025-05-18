package Omniframe::Role::Logging;

use exact -role, -conf;
use Log::Dispatch;
use Mojo::File 'path';
use Omniframe::Class::Time;
use Omniframe::Util::Output 'dp';
use Term::ANSIColor;

my $log_levels_definitions = {
    trace => 0,
    debug => 1,
    info  => 2,
    warn  => 3,
    error => 4,
    fatal => 5,

    notice    => 2,
    warning   => 3,
    critical  => 4,
    alert     => 5,
    emergency => 5,
    emerg     => 5,

    err  => 4,
    crit => 4,
};

my %color = (
    reset  => Term::ANSIColor::color('reset'),
    bold   => Term::ANSIColor::color('bold'),

    trace     => 'green',
    debug     => 'cyan',
    info      => 'white',
    notice    => 'bright_white',
    warning   => 'yellow',
    error     => 'bright_red',
    critical  => [ qw( underline bright_red ) ],
    alert     => [ qw( underline bright_yellow) ],
    emergency => [ qw( underline bright_yellow on_blue ) ],
);

my $time = Omniframe::Class::Time->new;

my ( $log_levels, $log_file, $log_level, $log_dispatch );

class_has log_levels => sub ($self) {
    return $log_levels //= [
        map { $_->[0] }
        sort {
            $a->[1] <=> $b->[1] ||
            $a->[0] cmp $b->[0]
        }
        map { [ $_, $log_levels_definitions->{$_} ] }
        keys %$log_levels_definitions
    ];
};

class_has log_file => sub ($self) {
    return $log_file if ($log_file);

    $log_file = join( '/',
        conf->get( qw( config_app root_dir ) ),
        conf->get( qw( logging log_file ) ),
    );

    path($log_file)->dirname->make_path;
    return $log_file;
};

class_has log_level => sub ($self) {
    return $log_level if ($log_level);

    my $log_level_conf = conf->get( 'logging', 'log_level' );

    my $env = (
        ( $ENV{CONFIGAPPENV} || $ENV{MOJO_MODE} || $ENV{PLACK_ENV} || 'development' ) eq 'production'
    ) ? 'production' : 'development';

    return $log_level = ( $log_level_conf->{$env} )
        ? $log_level_conf->{$env}
        : ( $env eq 'production' ) ? 'info' : 'debug';
};

class_has log_dispatch => sub ($self) {
    return $log_dispatch if ($log_dispatch);

    $log_dispatch = Log::Dispatch->new(
        outputs => [
            [
                'Screen',
                name      => 'stdout',
                min_level => _highest_level( $self->log_level, 'debug' ),
                max_level => 'notice',
                newline   => 1,
                callbacks => [ \&_log_cb_label, \&_log_cb_time, \&_log_cb_color ],
                stderr    => 0,
            ],
            [
                'Screen',
                name      => 'stderr',
                min_level => _highest_level( $self->log_level, 'warning' ),
                newline   => 1,
                callbacks => [ \&_log_cb_label, \&_log_cb_time, \&_log_cb_color ],
                stderr    => 1,
            ],
            [
                'File',
                name      => 'log_file',
                min_level => _highest_level( $self->log_level, 'debug' ),
                newline   => 1,
                callbacks => [ \&_log_cb_label, \&_log_cb_time, \&_log_cb_color ],
                mode      => 'append',
                autoflush => 1,
                filename  => $self->log_file,
                binmode   => ':encoding(UTF-8)',
            ],
            [
                'Email::Mailer',
                name      => 'email',
                min_level => _highest_level( $self->log_level, 'alert' ),
                to        => conf->get( 'logging', 'alert_email' ),
                subject   => conf->get( 'logging', 'alert_email_subject' ),
            ],
        ],
    );

    my $filter = conf->get( 'logging', 'filter' );
    $filter = ( ref $filter ) ? $filter : ($filter) ? [$filter] : [];
    $filter = [ map { $_->{name} } $log_dispatch->outputs ] if ( grep { lc($_) eq 'all' } @$filter );

    $log_dispatch->remove($_) for (@$filter);
    return $log_dispatch;
};

sub trace     ( $self, @params ) { return $self->log_dispatch->trace    ( dp( \@params ) ) }
sub debug     ( $self, @params ) { return $self->log_dispatch->debug    ( dp( \@params ) ) }
sub info      ( $self, @params ) { return $self->log_dispatch->info     ( dp( \@params ) ) }
sub notice    ( $self, @params ) { return $self->log_dispatch->notice   ( dp( \@params ) ) }
sub warning   ( $self, @params ) { return $self->log_dispatch->warning  ( dp( \@params ) ) }
sub warn      ( $self, @params ) { return $self->log_dispatch->warn     ( dp( \@params ) ) }
sub error     ( $self, @params ) { return $self->log_dispatch->error    ( dp( \@params ) ) }
sub err       ( $self, @params ) { return $self->log_dispatch->err      ( dp( \@params ) ) }
sub critical  ( $self, @params ) { return $self->log_dispatch->critical ( dp( \@params ) ) }
sub crit      ( $self, @params ) { return $self->log_dispatch->crit     ( dp( \@params ) ) }
sub alert     ( $self, @params ) { return $self->log_dispatch->alert    ( dp( \@params ) ) }
sub emergency ( $self, @params ) { return $self->log_dispatch->emergency( dp( \@params ) ) }
sub emerg     ( $self, @params ) { return $self->log_dispatch->emerg    ( dp( \@params ) ) }

sub _log_cb_time (%msg) {
    return $time->set->format('log') . ' ' . ( ( defined $msg{message} ) ? $msg{message} : '>undef<' );
}

sub _log_cb_label (%msg) {
    return '[' . uc( $msg{level} ) . '] ' . ( ( defined $msg{message} ) ? $msg{message} : '>undef<' );
}

sub _highest_level (@input) {
    return (
        map { $_->[1] }
        sort { $b->[0] <=> $a->[0] }
        map { [ $log_levels_definitions->{$_}, $_ ] }
        @input
    )[0];
}

for ( qw( trace debug info notice warning error critical alert emergency ) ) {
    next unless ( $color{$_} );
    $color{$_} = join ( '', map {
        $color{$_} = Term::ANSIColor::color($_) unless ( $color{$_} );
        $color{$_};
    } ( ( ref $color{$_} ) ? @{ $color{$_} } : $color{$_} ) );
}

sub _log_cb_color (%msg) {
    return ( $color{ $msg{level} } )
        ? $color{ $msg{level} } . ( ( defined $msg{message} ) ? $msg{message} : '>undef<' ) . $color{reset}
        : ( ( defined $msg{message} ) ? $msg{message} : '>undef<' );
}

1;

=head1 NAME

Omniframe::Role::Logging

=head1 SYNOPSIS

    package Package;

    use exact -class;

    with 'Omniframe::Role::Logging';

    sub method ($self) {
        $self->log_level('debug');
        say $self->log_file;

        $self->trace(     'trace-level detail logging (normally disabled)'     );
        $self->debug(     'everything at a pedantic level (normally disabled)' );
        $self->info(      'complete an action within a subsystem'              );
        $self->notice(    'service start, stop, restart, reload config, etc.'  );
        $self->warning(   'something to investigate when time allows'          );
        $self->error(     'something went wrong but probably not serious'      );
        $self->critical(  'non-repeating serious error'                        );
        $self->alert(     'repeating serious error'                            );
        $self->emergency( 'subsystem unresponsive or functionally broken'      );

        return;
    }

=head1 DESCRIPTION

This role provides a set of logging methods and constructs a L<Log::Dispatch>
object to dispatch logging events to reasonably useful locations. It will have
appropriate settings for logging along the 8 log levels defined by
L<Log::Dispatch>. It will also do some nifty things like adding ANSI color to
messages in text-based logs.

=head2 Log Level, Meanings, and Outputs

The following are the log levels and their meanings:

    trace     = trace-level detail logging (normally disabled)
    debug     = everything at a pedantic level (normally disabled)
    info      = completed actions within a subsystem
    notice    = service start, stop, restart, reload config, etc.
    warning   = something to investigate when time allows
    error     = something went wrong but probably not serious
    critical  = non-repeating serious error
    alert     = repeating serious error
    emergency = subsystem unresponsive or functionally broken

The following are the log levels and their outputs:

    trace     = STDOUT/Screen
    debug     = STDOUT/Screen
    info      = STDOUT/Screen, DBI
    notice    = STDOUT/Screen
    warning   = STDERR/Screen
    error     = STDERR/Screen, Email::EmailSender (on-call person)
    critical  = STDERR/Screen, Email::EmailSender (on-call person)
    alert     = STDERR/Screen, Email::EmailSender (universe), Twilio (on-call person)
    emergency = STDERR/Screen, Email::EmailSender (universe), Twilio (universe)

=head2 Log Objects

The following are the log objects and their log level ranges:

    debug  = debug
    stdout = info .. notice
    stderr = warning .. emergency

=head2 Alias Log Level Methods

In addition to the primary log level methods above, there are 5 additional alias
methods:

    warn  = warning
    err   = error
    crit  = critical
    fatal = alert
    emerg = emergency

=head1 CLASS ATTRIBUTES

Typically, you won't need to use the class attributes in normal use of this
role.

=head2 log_level

This class attribute sets the current log level. It's normally set automatically
based on the configuration: logging, log_level. See L</"CONFIGURATION"> below.

=head2 log_levels

This class attribute contains a list of all log level text names.

=head2 log_file

This class attribute sets the absolute path for the log file. If not set, it
will on first access use the logging, log_file configuration value as a relative
path (from the project's root directory). See L</"CONFIGURATION"> below.

=head2 log_dispatch

This class attribute will contain the L<Log::Dispatch> object that gets
generated automatically on first access of this attribute (typically by one of
the log level methods).

=head1 CONFIGURATION

The following is the default configuration, which can be overridden in the
application's configuration file. See L<Config::App>.

    logging:
        log_file: local/app.log
        log_level:
            production: info
            development: debug
        alert_email:
            - example@example.com
        alert_email_subject: Alert Log Message
        filter:
            - email

=head1 WITH ROLE

L<Omniframe::Role::Output>.

=begin Pod::Coverage

alert
crit
critical
debug
emerg
emergency
err
error
info
notice
trace
warn
warning

=end Pod::Coverage
