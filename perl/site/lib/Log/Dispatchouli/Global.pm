use strict;
use warnings;
package Log::Dispatchouli::Global;
BEGIN {
  $Log::Dispatchouli::Global::VERSION = '2.005';
}
# ABSTRACT: a system for sharing a global, dynamically-scoped logger

use Carp ();
use Log::Dispatchouli;
use Scalar::Util ();

use Sub::Exporter::GlobExporter 0.002 qw(glob_exporter); # pass-through args
use Sub::Exporter -setup => {
  collectors => {
    '$Logger' => glob_exporter(Logger => \'_build_logger'),
  },
};


sub logger_globref {
  no warnings 'once';
  \*Logger;
}

sub current_logger {
  my ($self) = @_;

  my $globref = $self->logger_globref;

  unless (defined $$$globref) {
    $$$globref = $self->default_logger;
  }

  return $$$globref;
}


sub default_logger {
  my ($self) = @_;

  my $ref = $self->default_logger_ref;

  $$ref ||= $self->default_logger_class->new(
    $self->default_logger_args
  );
}


sub default_logger_class { 'Log::Dispatchouli' }


sub default_logger_args {
  return {
    ident     => "default/$0",
    facility  => undef,
  }
}


my %default_logger_for_glob;

sub default_logger_ref {
  my ($self) = @_;

  my $glob = $self->logger_globref;
  my $addr = Scalar::Util::refaddr($glob);
  return \$default_logger_for_glob{ $addr };
}

sub _equiv {
  my ($self, $x, $y) = @_;

  return 1 if Scalar::Util::refaddr($x) == Scalar::Util::refaddr($y);
  return 1 if $x->config_id eq $y->config_id;
  return
}

sub _build_logger {
  my ($self, $arg) = @_;

  my $globref = $self->logger_globref;
  my $default = $self->default_logger;

  my $Logger  = $$$globref;

  if ($arg and $arg->{init}) {
    my $new_logger = $self->default_logger_class->new($arg->{init});

    if ($Logger
      and not(
        $self->_equiv($Logger, $new_logger)
        or
        $self->_equiv($Logger, $default)
      )
    ) {
      # We already set up a logger, so we'll check that our new one is
      # equivalent to the old.  If so, we'll keep the old, since it's good
      # enough.  If not, we'll raise an exception: you can't configure the
      # logger twice, with different configurations, in one program!
      # -- rjbs, 2011-01-21
      my $old = $Logger->config_id;
      my $new = $new_logger->config_id;

      Carp::confess(sprintf(
        "attempted to initialize %s logger twice; old config %s, new config %s",
        $self,
        $old,
        $new,
      ));
    }

    $$$globref = $new_logger;
  } else {
    $$$globref ||= $default;
  }

  return $globref;
}


1;

__END__
=pod

=head1 NAME

Log::Dispatchouli::Global - a system for sharing a global, dynamically-scoped logger

=head1 VERSION

version 2.005

=head1 DESCRIPTION

B<Warning>: This interface is still experimental.

Log::Dispatchouli::Global is a framework for a global logger object. In your
top-level programs that are actually executed, you'd add something like this:

  use Log::Dispatchouli::Global '$Logger' => {
    init => {
      ident     => 'My::Daemon',
      facility  => 'local2',
      to_stdout => 1,
    },
  };

This will import a C<$Logger> into your program, and more importantly will
initialize it with a new L<Log::Dispatchouli> object created by passing the
value for the C<init> parameter to Log::Dispatchouli's C<new> method.

Much of the rest of your program, across various libraries, can then just use
this:

  use Log::Dispatchouli::Global '$Logger';

  sub whatever {
    ...

    $Logger->log("about to do something");

    local $Logger = $Logger->proxy({ proxy_prefix => "whatever: " });

    for (@things) {
      $Logger->log([ "doing thing %s", $_ ]);
      ...
    }
  }

This eliminates the need to pass around what is effectively a global, while
still allowing it to be specialized withing certain contexts of your program.

B<Warning!>  Although you I<could> just use Log::Dispatchouli::Global as your
shared logging library, you almost I<certainly> want to write a subclass that
will only be shared amongst your application's classes.
Log::Dispatchouli::Global is meant to be subclassed and shared only within
controlled systems.  Remember, I<sharing your state with code you don't
control is dangerous>.

=head1 USING

In general, you will either be using a Log::Dispatchouli::Global class to get
a C<$Logger> or to initialize it (and then get C<$Logger>).  These are both
demonstrated above.  Also, when importing C<$Logger> you may request it be
imported under a different name:

  use Log::Dispatchouli::Global '$Logger' => { -as => 'L' };

  $L->log( ... );

There is only one class method that you are likely to use: C<current_logger>.
This provides the value of the shared logger from the caller's context,
initializing it to a default if needed.  Even this method is unlikely to be
required frequently, but it I<does> allow users to I<see> C<$Logger> without
importing it.

=head1 SUBCLASSING

Before using Log::Dispatchouli::Global in your application, you should subclass
it.  When you subclass it, you should provide the following methods:

=head2 logger_globref

This method should return a globref in which the shared logger will be stored.
Subclasses will be in their own package, so barring any need for cleverness,
every implementation of this method can look like the following:

  sub logger_globref { no warnings 'once'; return \*Logger }

=head2 default_logger

If no logger has been initialized, but something tries to log, it gets the
default logger, created by calling this method.

The default implementation calls C<new> on the C<default_logger_class> with the
result of C<default_logger_args> as the arguments.

=head2 default_logger_class

This returns the class on which C<new> will be called when initializing a
logger, either from the C<init> argument when importing or the default logger.

Its default value is Log::Dispatchouli.

=head2 default_logger_args

If no logger has been initialized, but something tries to log, it gets the
default logger, created by calling C<new> on the C<default_logger_class> and
passing the results of calling this method.

Its default return value creates a sink, so that anything logged without an
initialized logger is lost.

=head2 default_logger_ref

This method returns a scalar reference in which the cached default value is
stored for comparison.  This is used when someone tries to C<init> the global.
When someone tries to initialize the global logger, and it's already set, then:

=over 4

=item *

if the current value is the same as the default, the new value is set

=item *

if the current value is I<not> the same as the default, we die

=back

Since you want the default to be isolated to your application's logger, the
default behavior is default loggers are associated with the glob reference to
which the default might be assigned.  It is recommended that you replace this
method to return a shared, private variable for your subclasses, by putting the
following code in the base class for your Log::Dispatchouli::Global classes:

  my $default_logger;
  sub default_logger_ref { \$default_logger };

=head1 COOKBOOK

=head2 Common Logger Recipes

Say you often use the same configuration for one kind of program, like
automated tests.  You've already written your own subclass to get your own
storage and defaults, maybe C<MyApp::Logger>.

You can't just write a subclass with a different default, because if another
class using the same global has set the global with I<its> default, yours won't
be honored.  You don't just want this new value to be the default, you want it
to be I<the> logger.  What you want to do in this case is to initialize your
logger normally, then reexport it, like this:

  package MyApp::Logger::Test;
  use parent 'MyApp::Logger';

  use MyApp::Logger '$Logger' => {
    init => {
      ident    => "Tester($0)",
      to_self  => 1,
      facility => undef,
    },
  };

This will set up the logger and re-export it, and will properly die if anything
else attempts to initialize the logger to something else.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

