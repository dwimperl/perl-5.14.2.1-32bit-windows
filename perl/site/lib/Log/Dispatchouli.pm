use strict;
use warnings;
package Log::Dispatchouli;
BEGIN {
  $Log::Dispatchouli::VERSION = '2.005';
}
# ABSTRACT: a simple wrapper around Log::Dispatch

use Carp ();
use File::Spec ();
use Log::Dispatch;
use Params::Util qw(_ARRAY0 _HASH0 _CODELIKE);
use Scalar::Util qw(blessed weaken);
use String::Flogger;
use Try::Tiny 0.04;

our @CARP_NOT = qw(Log::Dispatchouli::Proxy);


sub new {
  my ($class, $arg) = @_;

  my $ident = $arg->{ident}
    or Carp::croak "no ident specified when using $class";

  my $config_id = defined $arg->{config_id} ? $arg->{config_id} : $ident;

  my %quiet_fatal;
  for ('quiet_fatal') {
    %quiet_fatal = map {; $_ => 1 } grep { defined }
      exists $arg->{$_}
        ? _ARRAY0($arg->{$_}) ? @{ $arg->{$_} } : $arg->{$_}
        : ('stderr');
  };

  my $pid_prefix = exists $arg->{log_pid} ? $arg->{log_pid} : 1;

  my $self = bless {} => $class;

  my $log = Log::Dispatch->new(
    callbacks => sub {
      return( ($pid_prefix ? "[$$] " : '') . {@_}->{message})
    },
  );

  if ($arg->{to_file}) {
    require Log::Dispatch::File;
    my $log_file = File::Spec->catfile(
      ($arg->{log_path} || $self->env_value('PATH') || File::Spec->tmpdir),
      $arg->{log_file} || sprintf('%s.%04u%02u%02u',
        $ident,
        ((localtime)[5] + 1900),
        sprintf('%02d', (localtime)[4] + 1),
        sprintf('%02d', (localtime)[3]),
      )
    );

    $log->add(
      Log::Dispatch::File->new(
        name      => 'logfile',
        min_level => 'debug',
        filename  => $log_file,
        mode      => 'append',
        callbacks => sub {
          # The time format returned here is subject to change. -- rjbs,
          # 2008-11-21
          return (localtime) . ' ' . {@_}->{message} . "\n"
        }
      )
    );
  }

  if ($arg->{facility} and not $self->env_value('NOSYSLOG')) {
    require Log::Dispatch::Syslog;
    $log->add(
      Log::Dispatch::Syslog->new(
        name      => 'syslog',
        min_level => 'debug',
        facility  => $arg->{facility},
        ident     => $ident,
        logopt    => 'pid',
        socket    => 'native',
        callbacks => sub {
          my %arg = @_;
          my $message = $arg{message};
          $message =~ s/\n/<LF>/g;
          return $message;
        },
      ),
    );
  }

  if ($arg->{to_self}) {
    $self->{events} = [];
    require Log::Dispatch::Array;
    $log->add(
      Log::Dispatch::Array->new(
        name      => 'self',
        min_level => 'debug',
        array     => $self->{events},
      ),
    );
  }

  DEST: for my $dest (qw(err out)) {
    next DEST unless $arg->{"to_std$dest"};
    require Log::Dispatch::Screen;
    $log->add(
      Log::Dispatch::Screen->new(
        name      => "std$dest",
        min_level => 'debug',
        stderr    => ($dest eq 'err' ? 1 : 0),
        callbacks => sub { my %arg = @_; "$arg{message}\n"; },
        ($quiet_fatal{"std$dest"} ? (max_level => 'info') : ()),
      ),
    );
  }

  $self->{dispatcher} = $log;
  $self->{prefix}     = $arg->{prefix};
  $self->{ident}      = $ident;
  $self->{config_id}  = $config_id;

  $self->{debug}  = exists $arg->{debug}
                  ? ($arg->{debug} ? 1 : 0)
                  : ($self->env_value('DEBUG') ? 1 : 0);

  $self->{fail_fatal} = exists $arg->{fail_fatal} ? $arg->{fail_fatal} : 1;

  return $self;
}


sub _join { shift; join q{ }, @{ $_[0] } }

sub log {
  my ($self, @rest) = @_;
  my $arg = _HASH0($rest[0]) ? shift(@rest) : {};

  my $message;

  if ($arg->{fatal} or ! $self->get_muted) {
    try {
      my $flogger = $self->string_flogger;
      my @flogged = map {; $flogger->flog($_) } @rest;
      $message    = @flogged > 1 ? $self->_join(\@flogged) : $flogged[0];

      my $prefix  = _ARRAY0($arg->{prefix})
                  ? [ @{ $arg->{prefix} } ]
                  : [ $arg->{prefix} ];

      for (reverse grep { defined } $self->get_prefix, @$prefix) {
        if (_CODELIKE( $_ )) {
          $message = $_->($message);
        } else {
          $message =~ s/^/$_/gm;
        }
      }

      $self->dispatcher->log(
        level   => $arg->{level} || 'info',
        message => $message,
      );
    } catch {
      $message = '(no message could be logged)' unless defined $message;
      die $_ if $self->{fail_fatal};
    };
  }

  Carp::croak $message if $arg->{fatal};

  return;
}


sub log_fatal {
  my ($self, @rest) = @_;

  my $arg = _HASH0($rest[0]) ? shift(@rest) : {}; # for future expansion

  local $arg->{level} = defined $arg->{level} ? $arg->{level} : 'error';
  local $arg->{fatal} = defined $arg->{fatal} ? $arg->{fatal} : 1;

  $self->log($arg, @rest);
}


sub log_debug {
  my ($self, @rest) = @_;

  return unless $self->is_debug;

  my $arg = _HASH0($rest[0]) ? shift(@rest) : {}; # for future expansion

  local $arg->{level} = defined $arg->{level} ? $arg->{level} : 'debug';

  $self->log($arg, @rest);
}


sub set_debug {
  return($_[0]->{debug} = $_[1] ? 1 : 0);
}


sub get_debug { return $_[0]->{debug} }


sub clear_debug { }

sub mute   { $_[0]{muted} = 1 }
sub unmute { $_[0]{muted} = 0 }


sub set_muted {
  return($_[0]->{muted} = $_[1] ? 1 : 0);
}


sub get_muted { return $_[0]->{muted} }


sub clear_muted { }


sub get_prefix   { return $_[0]->{prefix}  }
sub set_prefix   { $_[0]->{prefix} = $_[1] }
sub clear_prefix { $_[0]->unset_prefix     }
sub unset_prefix { undef $_[0]->{prefix}   }


sub ident { $_[0]{ident} }


sub config_id { $_[0]{config_id} }


sub string_flogger { 'String::Flogger' }


sub env_prefix { return; }


sub env_value {
  my ($self, $suffix) = @_;

  my @path = grep { defined } ($self->env_prefix, 'DISPATCHOULI');

  for my $prefix (@path) {
    my $name = join q{_}, $prefix, $suffix;
    return $ENV{ $name } if defined $ENV{ $name };
  }

  return;
}


sub new_tester {
  my ($class, $arg) = @_;
  $arg ||= {};

  return $class->new({
    ident     => "$$:$0",
    log_pid   => 0,
    %$arg,
    to_stderr => 0,
    to_stdout => 0,
    to_file   => 0,
    to_self   => 1,
    facility  => undef,
  });
}


sub events {
  Carp::confess "->events called on a logger not logging to self"
    unless $_[0]->{events};

  return $_[0]->{events};
}


sub clear_events {
  Carp::confess "->events called on a logger not logging to self"
    unless $_[0]->{events};

  @{ $_[0]->{events} } = ();
  return;
}


sub proxy {
  my ($self, $arg) = @_;
  $arg ||= {};

  require Log::Dispatchouli::Proxy;
  Log::Dispatchouli::Proxy->_new({
    parent => $self,
    logger => $self,
    proxy_prefix => $arg->{proxy_prefix},
    (exists $arg->{debug} ? (debug => ($arg->{debug} ? 1 : 0)) : ()),
  });
}


sub parent { $_[0] }
sub logger { $_[0] }


sub dispatcher   { $_[0]->{dispatcher} }


sub is_debug { $_[0]->get_debug }
sub is_info  { 1 }
sub is_fatal { 1 }

sub info  { shift()->log(@_); }
sub fatal { shift()->log_fatal(@_); }
sub debug { shift()->log_debug(@_); }

use overload
  '&{}'    => sub { my ($self) = @_; sub { $self->log(@_) } },
  fallback => 1,
;


1;

__END__
=pod

=head1 NAME

Log::Dispatchouli - a simple wrapper around Log::Dispatch

=head1 VERSION

version 2.005

=head1 SYNOPSIS

  my $logger = Log::Dispatchouli->new({
    ident     => 'stuff-purger',
    facility  => 'daemon',
    to_stdout => $opt->{print},
    debug     => $opt->{verbose}
  })

  $logger->log([ "There are %s items left to purge...", $stuff_left ]);

  $logger->log_debug("this is extra often-ignored debugging log");

  $logger->log_fatal("Now we will die!!");

=head1 DESCRIPTION

Log::Dispatchouli is a thin layer above L<Log::Dispatch> and meant to make it
dead simple to add logging to a program without having to think much about
categories, facilities, levels, or things like that.  It is meant to make
logging just configurable enough that you can find the logs you want and just
easy enough that you will actually log things.

Log::Dispatchouli can log to syslog (if you specify a facility), standard error
or standard output, to a file, or to an array in memory.  That last one is
mostly useful for testing.

In addition to providing as simple a way to get a handle for logging
operations, Log::Dispatchouli uses L<String::Flogger> to process the things to
be logged, meaning you can easily log data structures.  Basically: strings are
logged as is, arrayrefs are taken as (sprintf format, args), and subroutines
are called only if needed.  For more information read the L<String::Flogger>
docs.

=head1 METHODS

=head2 new

  my $logger = Log::Dispatchouli->new(\%arg);

This returns a new logger, a Log::Dispatchouli object.

Valid arguments are:

  ident       - the name of the thing logging (mandatory)
  to_self     - log to the logger object for testing; default: false
  to_stdout   - log to STDOUT; default: false
  to_stderr   - log to STDERR; default: false
  facility    - to which syslog facility to send logs; default: none

  to_file     - log to PROGRAM_NAME.YYYYMMDD in the log path; default: false
  log_file    - a leaf name for the file to log to with to_file
  log_path    - path in which to log to file; defaults to DISPATCHOULI_PATH
                environment variable or, failing that, to your system's tmpdir

  log_pid     - if true, prefix all log entries with the pid; default: true
  fail_fatal  - a boolean; if true, failure to log is fatal; default: true
  muted       - a boolean; if true, only fatals are logged; default: false
  debug       - a boolean; if true, log_debug method is not a no-op
                defaults to the truth of the DISPATCHOULI_DEBUG env var
  quiet_fatal - 'stderr' or 'stdout' or an arrayref of zero, one, or both
                fatal log messages will not be logged to these
                (default: stderr)
  config_id   - a name for this logger's config; rarely needed!

The log path is either F</tmp> or the value of the F<DISPATCHOULI_PATH> env var.

If the F<DISPATCHOULI_NOSYSLOG> env var is true, we don't log to syslog.

=head2 log

  $logger->log(@messages);

  $logger->log(\%arg, @messages);

This method uses L<String::Flogger> on the input, then logs the result.  Each
message is flogged individually, then joined with spaces.

If the first argument is a hashref, it will be used as extra arguments to
logging.  It may include a C<prefix> entry to preprocess the message by
prepending a string (if the prefix is a string) or calling a subroutine to
generate a new message (if the prefix is a coderef).

=head2 log_fatal

This behaves like the C<log> method, but will throw the logged string as an
exception after logging.

This method can also be called as C<fatal>, to match other popular logging
interfaces.  B<If you want to override this method, you must override
C<log_fatal> and not C<fatal>>.

=head2 log_debug

This behaves like the C<log> method, but will only log (at the debug level) if
the logger object has its debug property set to true.

This method can also be called as C<debug>, to match other popular logging
interfaces.  B<If you want to override this method, you must override
C<log_debug> and not C<debug>>.

=head2 set_debug

  $logger->set_debug($bool);

This sets the logger's debug property, which affects the behavior of
C<log_debug>.

=head2 get_debug

This gets the logger's debug property, which affects the behavior of
C<log_debug>.

=head2 clear_debug

This method does nothing, and is only useful for L<Log::Dispatchouli::Proxy>
objects.  See L<Methods for Proxy Loggers|/METHODS FOR PROXY LOGGERS>, below.

=head2 set_muted

  $logger->set_muted($bool);

This sets the logger's muted property, which affects the behavior of
C<log>.

=head2 get_muted

This gets the logger's muted property, which affects the behavior of
C<log>.

=head2 clear_muted

This method does nothing, and is only useful for L<Log::Dispatchouli::Proxy>
objects.  See L<Methods for Proxy Loggers|/METHODS FOR PROXY LOGGERS>, below.

=head2 get_prefix

  my $prefix = $logger->get_prefix;

This method returns the currently-set prefix for the logger, which may be a
string or code reference or undef.  See L<Logger Prefix|/LOGGER PREFIX>.

=head2 set_prefix

  $logger->set_prefix( $new_prefix );

This method changes the prefix.  See L<Logger Prefix|/LOGGER PREFIX>.

=head2 clear_prefix

This method clears any set logger prefix.  (It can also be called as
C<unset_prefix>, but this is deprecated.  See L<Logger Prefix|/LOGGER PREFIX>.

=head2 ident

This method returns the logger's ident.

=head2 config_id

This method returns the logger's configuration id, which defaults to its ident.
This can be used to make two loggers equivalent in Log::Dispatchouli::Global so
that trying to reinitialize with a new logger with the same C<config_id> as the
current logger will not throw an exception, and will simply do no thing.

=head2 dispatcher

This returns the underlying Log::Dispatch object.  This is not the method
you're looking for.  Move along.

=head1 LOGGER PREFIX

Log messages may be prepended with information to set context.  This can be set
at a logger level or per log item.  The simplest example is:

  my $logger = Log::Dispatchouli->new( ... );

  $logger->set_prefix("Batch 123: ");

  $logger->log("begun processing");

  # ...

  $logger->log("finished processing");

The above will log something like:

  Batch 123: begun processing
  Batch 123: finished processing

To pass a prefix per-message:

  $logger->log({ prefix => 'Sub-Item 234: ', 'error!' })

  # Logs: Batch 123: Sub-Item 234: error!

If the prefix is a string, it is prepended to each line of the message.  If it
is a coderef, it is called and passed the message to be logged.  The return
value is logged instead.

L<Proxy loggers|/METHODS FOR PROXY LOGGERS> also have their own prefix
settings, which accumulate.  So:

  my $proxy = $logger->proxy({ proxy_prefix => 'Subsystem 12: ' });

  $proxy->set_prefix('Page 9: ');

  $proxy->log({ prefix => 'Paragraph 6: ' }, 'Done.');

...will log...

  Batch 123: Subsystem 12: Page 9: Paragraph 6: Done.

=head1 METHODS FOR SUBCLASSING

=head2 string_flogger

This method returns the thing on which F<flog> will be called to format log
messages.  By default, it just returns C<String::Flogger>

=head2 env_prefix

This method should return a string used as a prefix to find environment
variables that affect the logger's behavior.  For example, if this method
returns C<XYZZY> then when checking the environment for a default value for the
C<debug> parameter, Log::Dispatchouli will first check C<XYZZY_DEBUG>, then
C<DISPATCHOULI_DEBUG>.

By default, this method returns C<()>, which means no extra environment
variable is checked.

=head2 env_value

  my $value = $logger->env_value('DEBUG');

This method returns the value for the environment variable suffix given.  For
example, the example given, calling with C<DEBUG> will check
C<DISPATCHOULI_DEBUG>.

=head1 METHODS FOR TESTING

=head2 new_tester

  my $logger = Log::Dispatchouli->new_tester( \%arg );

This returns a new logger that logs only C<to_self>.  It's useful in testing.
If no C<ident> arg is provided, one will be generated.  C<log_pid> is off by
default, but can be overridden.

C<\%arg> is optional.

=head2 events

This method returns the arrayref of events logged to an array in memory (in the
logger).  If the logger is not logging C<to_self> this raises an exception.

=head2 clear_events

This method empties the current sequence of events logged into an array in
memory.  If the logger is not logging C<to_self> this raises an exception.

=head1 METHODS FOR PROXY LOGGERS

=head2 proxy

  my $proxy_logger = $logger->proxy( \%arg );

This method returns a new proxy logger -- an instance of
L<Log::Dispatchouli::Proxy> -- which will log through the given logger, but
which may have some settings localized.

C<%arg> is optional.  It may contain the following entries:

=over 4

=item proxy_prefix

This is a prefix that will be applied to anything the proxy logger logs, and
cannot be changed.

=item debug

This can be set to true or false to change the proxy's "am I in debug mode?"
setting.  It can be changed or cleared later on the proxy.

=back

=head2 parent

=head2 logger

These methods return the logger itself.  (They're more useful when called on
proxy loggers.)

=head1 METHODS FOR API COMPATIBILITY

To provide compatibility with some other loggers, most specifically
L<Log::Contextual>, the following methods are provided.  You should not use
these methods without a good reason, and you should never subclass them.
Instead, subclass the methods they call.

=over 4

=item is_debug

This method calls C<get_debug>.

=item is_info

=item is_fatal

These methods return true.

=item info

=item fatal

=item debug

These methods redispatch to C<log>, C<log_fatal>, and C<log_debug>
respectively.

=back

=head1 SEE ALSO

=over 4

=item *

L<Log::Dispatch>

=item *

L<String::Flogger>

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

