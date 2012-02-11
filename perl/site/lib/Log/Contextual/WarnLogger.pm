package Log::Contextual::WarnLogger;

use strict;
use warnings;

{
  my @levels = (qw( trace debug info warn error fatal ));
  my %level_num; @level_num{ @levels } = (0 .. $#levels);
  for my $name (@levels) {

    no strict 'refs';

    my $is_name = "is_$name";
    *{$name} = sub {
      my $self = shift;

      $self->_log( $name, @_ )
        if $self->$is_name;
    };

    *{$is_name} = sub {
      my $self = shift;
      return 1 if $ENV{$self->{env_prefix} . '_' . uc $name};
      my $upto = $ENV{$self->{env_prefix} . '_UPTO'};
      return unless $upto;
      $upto = lc $upto;

      return $level_num{$name} >= $level_num{$upto};
    };
  }
}

sub new {
  my ($class, $args) = @_;
  my $self = bless {}, $class;

  $self->{env_prefix} = $args->{env_prefix} or
     die 'no env_prefix passed to Log::Contextual::WarnLogger->new';
  return $self;
}

sub _log {
  my $self    = shift;
  my $level   = shift;
  my $message = join( "\n", @_ );
  $message .= "\n" unless $message =~ /\n$/;
  warn "[$level] $message";
}

1;

__END__

=head1 NAME

Log::Contextual::WarnLogger - Simple logger for libraries using Log::Contextual

=head1 SYNOPSIS

 package My::Package;
 use Log::Contextual::WarnLogger;
 use Log::Contextual qw( :log ),
   -default_logger => Log::Contextual::WarnLogger->new({
      env_prefix => 'MY_PACKAGE'
   });

 # warns '[info] program started' if $ENV{MY_PACKAGE_TRACE} is set
 log_info { 'program started' }; # no-op because info is not in levels
 sub foo {
   # warns '[debug] entered foo' if $ENV{MY_PACKAGE_DEBUG} is set
   log_debug { 'entered foo' };
   ...
 }

=head1 DESCRIPTION

This module is a simple logger made for libraries using L<Log::Contextual>.  We
recommend the use of this logger as your default logger as it is simple and
useful for most users, yet users can use L<Log::Contextual/set_logger> to override
your choice of logger in their own code thanks to the way L<Log::Contextual>
works.

=head1 METHODS

=head2 new

Arguments: C<< Dict[ env_prefix => Str ] $conf >>

 my $l = Log::Contextual::WarnLogger->new({
   env_prefix
 });

Creates a new logger object where C<env_prefix> defines what the prefix is for
the environment variables that will be checked for the six log levels.  For
example, if C<env_prefix> is set to C<FREWS_PACKAGE> the following environment
variables will be used:

 FREWS_PACKAGE_UPTO

 FREWS_PACKAGE_TRACE
 FREWS_PACKAGE_DEBUG
 FREWS_PACKAGE_INFO
 FREWS_PACKAGE_WARN
 FREWS_PACKAGE_ERROR
 FREWS_PACKAGE_FATAL

Note that C<UPTO> is a convenience variable.  If you set
C<< FOO_UPTO=TRACE >> it will enable all log levels.  Similarly, if you
set it to C<FATAL> only fatal will be enabled.

=head2 $level

Arguments: C<@anything>

All of the following six methods work the same.  The basic pattern is:

 sub $level {
   my $self = shift;

   warn "[$level] " . join qq{\n}, @_;
      if $self->is_$level;
 }

=head3 trace

 $l->trace( 'entered method foo with args ' join q{,}, @args );

=head3 debug

 $l->debug( 'entered method foo' );

=head3 info

 $l->info( 'started process foo' );

=head3 warn

 $l->warn( 'possible misconfiguration at line 10' );

=head3 error

 $l->error( 'non-numeric user input!' );

=head3 fatal

 $l->fatal( '1 is never equal to 0!' );

=head2 is_$level

All of the following six functions just return true if their respective
environment variable is enabled.

=head3 is_trace

 say 'tracing' if $l->is_trace;

=head3 is_debug

 say 'debuging' if $l->is_debug;

=head3 is_info

 say q{info'ing} if $l->is_info;

=head3 is_warn

 say 'warning' if $l->is_warn;

=head3 is_error

 say 'erroring' if $l->is_error;

=head3 is_fatal

 say q{fatal'ing} if $l->is_fatal;

=head1 AUTHOR

See L<Log::Contextual/"AUTHOR">

=head1 COPYRIGHT

See L<Log::Contextual/"COPYRIGHT">

=head1 LICENSE

See L<Log::Contextual/"LICENSE">

=cut

