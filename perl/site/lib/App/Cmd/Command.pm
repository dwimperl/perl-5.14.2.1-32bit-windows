use strict;
use warnings;

package App::Cmd::Command;
{
  $App::Cmd::Command::VERSION = '0.316';
}
use App::Cmd::ArgProcessor;
BEGIN { our @ISA = 'App::Cmd::ArgProcessor' };

# ABSTRACT: a base class for App::Cmd commands

use Carp ();


sub prepare {
  my ($class, $app, @args) = @_;

  my ($opt, $args, %fields)
    = $class->_process_args(\@args, $class->_option_processing_params($app));

  return (
    $class->new({ app => $app, %fields }),
    $opt,
    @$args,
  );
}

sub _option_processing_params {
  my ($class, @args) = @_;

  return (
    $class->usage_desc(@args),
    $class->opt_spec(@args),
  );
}


sub new {
  my ($class, $arg) = @_;
  bless $arg => $class;
}


sub execute {
  my $class = shift;

  if (my $run = $class->can('run')) {
    warn "App::Cmd::Command subclasses should implement ->execute not ->run"
      if $ENV{HARNESS_ACTIVE};

    return $class->$run(@_);
  }

  Carp::croak ref($class) . " does not implement mandatory method 'execute'\n";
}


sub app { $_[0]->{app}; }


sub usage { $_[0]->{usage}; }


sub command_names {
  # from UNIVERSAL::moniker
  (ref( $_[0] ) || $_[0]) =~ /([^:]+)$/;
  return lc $1;
}


sub usage_desc {
  my ($self) = @_;

  my ($command) = $self->command_names;
  return "%c $command %o"
}


sub opt_spec {
  return;
}


sub validate_args { }


sub usage_error {
  my ( $self, $error ) = @_;
  die "Error: $error\nUsage: " . $self->_usage_text;
}

sub _usage_text {
  my ($self) = @_;
  local $@;
  join "\n", eval { $self->app->_usage_text }, eval { $self->usage->text };
}


# stolen from ExtUtils::MakeMaker
sub abstract {
  my ($class) = @_;
  $class = ref $class if ref $class;

  my $result;
  my $weaver_abstract;

  # classname to filename
  (my $pm_file = $class) =~ s!::!/!g;
  $pm_file .= '.pm';
  $pm_file = $INC{$pm_file};

  # if the pm file exists, open it and parse it
  open my $fh, "<", $pm_file or return "(unknown)";

  local $/ = "\n";
  my $inpod;

  while (local $_ = <$fh>) {
    # =cut toggles, it doesn't end :-/
    $inpod = /^=cut/ ? !$inpod : $inpod || /^=(?!cut)/;

    if (/#+\s*ABSTRACT: (.*)/){
      # takes ABSTRACT: ... if no POD defined yet
      $weaver_abstract = $1;
    }

    next unless $inpod;
    chomp;

    next unless /^(?:$class\s-\s)(.*)/;

    $result = $1;
    last;
  }

  return $result || $weaver_abstract || "(unknown)";
}


sub description { '' }

1;

__END__
=pod

=head1 NAME

App::Cmd::Command - a base class for App::Cmd commands

=head1 VERSION

version 0.316

=head1 METHODS

=head2 prepare

  my ($cmd, $opt, $args) = $class->prepare($app, @args);

This method is the primary way in which App::Cmd::Command objects are built.
Given the remaining command line arguments meant for the command, it returns
the Command object, parsed options (as a hashref), and remaining arguments (as
an arrayref).

In the usage above, C<$app> is the App::Cmd object that is invoking the
command.

=head2 new

This returns a new instance of the command plugin.  Probably only C<prepare>
should use this.

=head2 execute

=head2 app

This method returns the App::Cmd object into which this command is plugged.

=head2 usage

This method returns the usage object for this command.  (See
L<Getopt::Long::Descriptive>).

=head2 command_names

This method returns a list of command names handled by this plugin.  If this
method is not overridden by a App::Cmd::Command subclass, it will return the
last part of the plugin's package name, converted to lowercase.

For example, YourApp::Cmd::Command::Init will, by default, handle the command
"init"

=head2 usage_desc

This method should be overridden to provide a usage string.  (This is the first
argument passed to C<describe_options> from Getopt::Long::Descriptive.)

If not overridden, it returns "%c COMMAND %o";  COMMAND is the first item in
the result of the C<command_names> method.

=head2 opt_spec

This method should be overridden to provide option specifications.  (This is
list of arguments passed to C<describe_options> from Getopt::Long::Descriptive,
after the first.)

If not overridden, it returns an empty list.

=head2 validate_args

  $command_plugin->validate_args(\%opt, \@args);

This method is passed a hashref of command line options (as processed by
Getopt::Long::Descriptive) and an arrayref of leftover arguments.  It may throw
an exception (preferably by calling C<usage_error>, below) if they are invalid,
or it may do nothing to allow processing to continue.

=head2 usage_error

  $self->usage_error("This command must not be run by root!");

This method should be called to die with human-friendly usage output, during
C<validate_args>.

=head2 abstract

This method returns a short description of the command's purpose.  If this
method is not overridden, it will return the abstract from the module's Pod.
If it can't find the abstract, it will look for a comment starting with
"ABSTRACT:" like the ones used by L<Pod::Weaver::Section::Name>.

=head2 description

This method should be overridden to provide full option description. It
is used by the help command.

If not overridden, it returns an empty string.

=for Pod::Coverage run

  $command_plugin->execute(\%opt, \@args);

This method does whatever it is the command should do!  It is passed a hash
reference of the parsed command-line options and an array reference of left
over arguments.

If no C<execute> method is defined, it will try to call C<run> -- but it will
warn about this behavior during testing, to remind you to fix the method name!

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

