package Log::Contextual;

use strict;
use warnings;

our $VERSION = '0.004001';

my @levels = qw(debug trace warn info error fatal);

use Exporter::Declare;
use Exporter::Declare::Export::Generator;
use Data::Dumper::Concise;
use Scalar::Util 'blessed';

my @dlog = ((map "Dlog_$_", @levels), (map "DlogS_$_", @levels));

my @log = ((map "log_$_", @levels), (map "logS_$_", @levels));

eval {
   require Log::Log4perl;
   die if $Log::Log4perl::VERSION < 1.29;
   Log::Log4perl->wrapper_register(__PACKAGE__)
};

# ____ is because tags must have at least one export and we don't want to
# export anything but the levels selected
sub ____ {}

exports ('____',
   @dlog, @log,
   qw( set_logger with_logger )
);

export_tag dlog => ('____');
export_tag log  => ('____');
import_arguments qw(logger package_logger default_logger);

sub before_import {
   my ($class, $importer, $spec) = @_;

   die 'Log::Contextual does not have a default import list'
      if $spec->config->{default};

   my @levels = @{$class->arg_levels($spec->config->{levels})};
   for my $level (@levels) {
      if ($spec->config->{log}) {
         $spec->add_export("&log_$level", sub (&@) {
            _do_log( $level => _get_logger( caller ), shift @_, @_)
         });
         $spec->add_export("&logS_$level", sub (&@) {
            _do_logS( $level => _get_logger( caller ), $_[0], $_[1])
         });
      }
      if ($spec->config->{dlog}) {
         $spec->add_export("&Dlog_$level", sub (&@) {
           my ($code, @args) = @_;
           return _do_log( $level => _get_logger( caller ), sub {
              local $_ = (@args?Data::Dumper::Concise::Dumper @args:'()');
              $code->(@_)
           }, @args );
         });
         $spec->add_export("&DlogS_$level", sub (&$) {
           my ($code, $ref) = @_;
           _do_logS( $level => _get_logger( caller ), sub {
              local $_ = Data::Dumper::Concise::Dumper $ref;
              $code->($ref)
           }, $ref )
         });
      }
   }
}

sub arg_logger { $_[1] }
sub arg_levels { $_[1] || [qw(debug trace warn info error fatal)] }
sub arg_package_logger { $_[1] }
sub arg_default_logger { $_[1] }

sub after_import {
   my ($class, $importer, $specs) = @_;

   if (my $l = $class->arg_logger($specs->config->{logger})) {
      set_logger($l)
   }

   if (my $l = $class->arg_package_logger($specs->config->{package_logger})) {
      _set_package_logger_for($importer, $l)
   }

   if (my $l = $class->arg_default_logger($specs->config->{default_logger})) {
      _set_default_logger_for($importer, $l)
   }
}

our $Get_Logger;
our %Default_Logger;
our %Package_Logger;

sub _set_default_logger_for {
   my $logger = $_[1];
   if(ref $logger ne 'CODE') {
      die 'logger was not a CodeRef or a logger object.  Please try again.'
         unless blessed($logger);
      $logger = do { my $l = $logger; sub { $l } }
   }
   $Default_Logger{$_[0]} = $logger
}

sub _set_package_logger_for {
   my $logger = $_[1];
   if(ref $logger ne 'CODE') {
      die 'logger was not a CodeRef or a logger object.  Please try again.'
         unless blessed($logger);
      $logger = do { my $l = $logger; sub { $l } }
   }
   $Package_Logger{$_[0]} = $logger
}

sub _get_logger($) {
   my $package = shift;
   (
      $Package_Logger{$package} ||
      $Get_Logger ||
      $Default_Logger{$package} ||
      die q( no logger set!  you can't try to log something without a logger! )
   )->($package);
}

sub set_logger {
   my $logger = $_[0];
   if(ref $logger ne 'CODE') {
      die 'logger was not a CodeRef or a logger object.  Please try again.'
         unless blessed($logger);
      $logger = do { my $l = $logger; sub { $l } }
   }

   warn 'set_logger (or -logger) called more than once!  This is a bad idea!'
      if $Get_Logger;
   $Get_Logger = $logger;
}

sub with_logger {
   my $logger = $_[0];
   if(ref $logger ne 'CODE') {
      die 'logger was not a CodeRef or a logger object.  Please try again.'
         unless blessed($logger);
      $logger = do { my $l = $logger; sub { $l } }
   }
   local $Get_Logger = $logger;
   $_[1]->();
}

sub _do_log {
   my $level  = shift;
   my $logger = shift;
   my $code   = shift;
   my @values = @_;

   $logger->$level($code->(@_))
      if $logger->${\"is_$level"};
   @values
}

sub _do_logS {
   my $level  = shift;
   my $logger = shift;
   my $code   = shift;
   my $value  = shift;

   $logger->$level($code->($value))
      if $logger->${\"is_$level"};
   $value
}

1;

__END__

=head1 NAME

Log::Contextual - Simple logging interface with a contextual log

=head1 SYNOPSIS

 use Log::Contextual qw( :log :dlog set_logger with_logger );
 use Log::Contextual::SimpleLogger;
 use Log::Log4perl ':easy';
 Log::Log4perl->easy_init($DEBUG);


 my $logger  = Log::Log4perl->get_logger;

 set_logger $logger;

 log_debug { 'program started' };

 sub foo {
   with_logger(Log::Contextual::SimpleLogger->new({
       levels => [qw( trace debug )]
     }) => sub {
     log_trace { 'foo entered' };
     my ($foo, $bar) = Dlog_trace { "params for foo: $_" } @_;
     # ...
     log_trace { 'foo left' };
   });
 }

 foo();

Beginning with version 1.008 L<Log::Dispatchouli> also works out of the box
with C<Log::Contextual>:

 use Log::Contextual qw( :log :dlog set_logger );
 use Log::Dispatchouli;
 my $ld = Log::Dispatchouli->new({
    ident     => 'slrtbrfst',
    to_stderr => 1,
    debug     => 1,
 });

 set_logger $ld;

 log_debug { 'program started' };

=head1 DESCRIPTION

This module is a simple interface to extensible logging.  It is bundled with a
really basic logger, L<Log::Contextual::SimpleLogger>, but in general you
should use a real logger instead of that.  For something more serious but not
overly complicated, try L<Log::Dispatchouli> (see L</SYNOPSIS> for example.)

The reason for this module is to abstract your logging interface so that
logging is as painless as possible, while still allowing you to switch from one
logger to another.

=head1 A WORK IN PROGRESS

This module is certainly not complete, but we will not break the interface
lightly, so I would say it's safe to use in production code.  The main result
from that at this point is that doing:

 use Log::Contextual;

will die as we do not yet know what the defaults should be.  If it turns out
that nearly everyone uses the C<:log> tag and C<:dlog> is really rare, we'll
probably make C<:log> the default.  But only time and usage will tell.

=head1 IMPORT OPTIONS

See L</SETTING DEFAULT IMPORT OPTIONS> for information on setting these project
wide.

=head2 -logger

When you import this module you may use C<-logger> as a shortcut for
L<set_logger>, for example:

 use Log::Contextual::SimpleLogger;
 use Log::Contextual qw( :dlog ),
   -logger => Log::Contextual::SimpleLogger->new({ levels => [qw( debug )] });

sometimes you might want to have the logger handy for other stuff, in which
case you might try something like the following:

 my $var_log;
 BEGIN { $var_log = VarLogger->new }
 use Log::Contextual qw( :dlog ), -logger => $var_log;

=head2 -levels

The C<-levels> import option allows you to define exactly which levels your
logger supports.  So the default,
C<< [qw(debug trace warn info error fatal)] >>, works great for
L<Log::Log4perl>, but it doesn't support the levels for L<Log::Dispatch>.  But
supporting those levels is as easy as doing

 use Log::Contextual
   -levels => [qw( debug info notice warning error critical alert emergency )];

=head2 -package_logger

The C<-package_logger> import option is similar to the C<-logger> import option
except C<-package_logger> sets the the logger for the current package.

Unlike L</-default_logger>, C<-package_logger> cannot be overridden with
L</set_logger>.

 package My::Package;
 use Log::Contextual::SimpleLogger;
 use Log::Contextual qw( :log ),
   -package_logger => Log::Contextual::WarnLogger->new({
      env_prefix => 'MY_PACKAGE'
   });

If you are interested in using this package for a module you are putting on
CPAN we recommend L<Log::Contextual::WarnLogger> for your package logger.

=head2 -default_logger

The C<-default_logger> import option is similar to the C<-logger> import option
except C<-default_logger> sets the the B<default> logger for the current package.

Basically it sets the logger to be used if C<set_logger> is never called; so

 package My::Package;
 use Log::Contextual::SimpleLogger;
 use Log::Contextual qw( :log ),
   -default_logger => Log::Contextual::WarnLogger->new({
      env_prefix => 'MY_PACKAGE'
   });

=head1 SETTING DEFAULT IMPORT OPTIONS

Eventually you will get tired of writing the following in every single one of
your packages:

 use Log::Log4perl;
 use Log::Log4perl ':easy';
 BEGIN { Log::Log4perl->easy_init($DEBUG) }

 use Log::Contextual -logger => Log::Log4perl->get_logger;

You can set any of the import options for your whole project if you define your
own C<Log::Contextual> subclass as follows:

 package MyApp::Log::Contextual;

 use base 'Log::Contextual';

 use Log::Log4perl ':easy';
 Log::Log4perl->easy_init($DEBUG)

 sub arg_logger { $_[1] || Log::Log4perl->get_logger }
 sub arg_levels { [qw(debug trace warn info error fatal custom_level)] }

 # and *maybe* even these:
 sub arg_package_logger { $_[1] }
 sub arg_default_logger { $_[1] }

Note the C<< $_[1] || >> in C<arg_logger>.  All of these methods are passed the
values passed in from the arguments to the subclass, so you can either throw
them away, honor them, die on usage, or whatever.  To be clear, if you define
your subclass, and someone uses it as follows:

 use MyApp::Log::Contextual -logger => $foo, -levels => [qw(bar baz biff)];

Your C<arg_logger> method will get C<$foo> and your C<arg_levels>
will get C<[qw(bar baz biff)]>;

=head1 FUNCTIONS

=head2 set_logger

 my $logger = WarnLogger->new;
 set_logger $logger;

Arguments: C<Ref|CodeRef $returning_logger>

C<set_logger> will just set the current logger to whatever you pass it.  It
expects a C<CodeRef>, but if you pass it something else it will wrap it in a
C<CodeRef> for you.  C<set_logger> is really meant only to be called from a
top-level script.  To avoid foot-shooting the function will warn if you call it
more than once.

=head2 with_logger

 my $logger = WarnLogger->new;
 with_logger $logger => sub {
    if (1 == 0) {
       log_fatal { 'Non Logical Universe Detected' };
    } else {
       log_info  { 'All is good' };
    }
 };

Arguments: C<Ref|CodeRef $returning_logger, CodeRef $to_execute>

C<with_logger> sets the logger for the scope of the C<CodeRef> C<$to_execute>.
As with L</set_logger>, C<with_logger> will wrap C<$returning_logger> with a
C<CodeRef> if needed.

=head2 log_$level

Import Tag: C<:log>

Arguments: C<CodeRef $returning_message, @args>

All of the following six functions work the same except that a different method
is called on the underlying C<$logger> object.  The basic pattern is:

 sub log_$level (&@) {
   if ($logger->is_$level) {
     $logger->$level(shift->(@_));
   }
   @_
 }

Note that the function returns it's arguments.  This can be used in a number of
ways, but often it's convenient just for partial inspection of passthrough data

 my @friends = log_trace {
   'friends list being generated, data from first friend: ' .
     Dumper($_[0]->TO_JSON)
 } generate_friend_list();

If you want complete inspection of passthrough data, take a look at the
L</Dlog_$level> functions.

=head3 log_trace

 log_trace { 'entered method foo with args ' join q{,}, @args };

=head3 log_debug

 log_debug { 'entered method foo' };

=head3 log_info

 log_info { 'started process foo' };

=head3 log_warn

 log_warn { 'possible misconfiguration at line 10' };

=head3 log_error

 log_error { 'non-numeric user input!' };

=head3 log_fatal

 log_fatal { '1 is never equal to 0!' };

=head2 logS_$level

Import Tag: C<:log>

Arguments: C<CodeRef $returning_message, Item $arg>

This is really just a special case of the L</log_$level> functions.  It forces
scalar context when that is what you need.  Other than that it works exactly
same:

 my $friend = logS_trace {
   'I only have one friend: ' .  Dumper($_[0]->TO_JSON)
 } friend();

See also: L</DlogS_$level>.

=head2 Dlog_$level

Import Tag: C<:dlog>

Arguments: C<CodeRef $returning_message, @args>

All of the following six functions work the same as their L</log_$level>
brethren, except they return what is passed into them and put the stringified
(with L<Data::Dumper::Concise>) version of their args into C<$_>.  This means
you can do cool things like the following:

 my @nicks = Dlog_debug { "names: $_" } map $_->value, $frew->names->all;

and the output might look something like:

 names: "fREW"
 "fRIOUX"
 "fROOH"
 "fRUE"
 "fiSMBoC"

=head3 Dlog_trace

 my ($foo, $bar) = Dlog_trace { "entered method foo with args: $_" } @_;

=head3 Dlog_debug

 Dlog_debug { "random data structure: $_" } { foo => $bar };

=head3 Dlog_info

 return Dlog_info { "html from method returned: $_" } "<html>...</html>";

=head3 Dlog_warn

 Dlog_warn { "probably invalid value: $_" } $foo;

=head3 Dlog_error

 Dlog_error { "non-numeric user input! ($_)" } $port;

=head3 Dlog_fatal

 Dlog_fatal { '1 is never equal to 0!' } 'ZOMG ZOMG' if 1 == 0;

=head2 DlogS_$level

Import Tag: C<:dlog>

Arguments: C<CodeRef $returning_message, Item $arg>

Like L</logS_$level>, these functions are a special case of L</Dlog_$level>.
They only take a single scalar after the C<$returning_message> instead of
slurping up (and also setting C<wantarray>) all the C<@args>

 my $pals_rs = DlogS_debug { "pals resultset: $_" }
   $schema->resultset('Pals')->search({ perlers => 1 });

=head1 LOGGER INTERFACE

Because this module is ultimately pretty looking glue (glittery?) with the
awesome benefit of the Contextual part, users will often want to make their
favorite logger work with it.  The following are the methods that should be
implemented in the logger:

 is_trace
 is_debug
 is_info
 is_warn
 is_error
 is_fatal
 trace
 debug
 info
 warn
 error
 fatal

The first six merely need to return true if that level is enabled.  The latter
six take the results of whatever the user returned from their coderef and log
them.  For a basic example see L<Log::Contextual::SimpleLogger>.

=head1 AUTHOR

frew - Arthur Axel "fREW" Schmidt <frioux@gmail.com>

=head1 DESIGNER

mst - Matt S. Trout <mst@shadowcat.co.uk>

=head1 COPYRIGHT

Copyright (c) 2010 the Log::Contextual L</AUTHOR> and L</DESIGNER> as listed
above.

=head1 LICENSE

This library is free software and may be distributed under the same terms as
Perl 5 itself.

=cut

