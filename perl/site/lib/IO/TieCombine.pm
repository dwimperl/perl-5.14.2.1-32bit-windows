use strict;
use warnings;
package IO::TieCombine;
{
  $IO::TieCombine::VERSION = '1.001';
}
# ABSTRACT: produce tied (and other) separate but combined variables

use Carp ();
use IO::TieCombine::Handle;
use IO::TieCombine::Scalar;
use Symbol ();



sub new {
  my ($class) = @_;

  my $self = {
    combined => \(my $str = ''),
    slots    => { },
  };

  bless $self => $class;
}


sub combined_contents {
  my ($self) = @_;
  return ${ $self->{combined} };
}


sub slot_contents {
  my ($self, $name) = @_;
  Carp::confess("no name provided for slot_contents") unless defined $name;

  Carp::confess("no such output slot exists")
    unless exists $self->{slots}{$name};

  return ${ $self->{slots}{$name} };
}

sub _slot_ref {
  my ($self, $name) = @_;
  Carp::confess("no slot name provided") unless defined $name;

  $self->{slots}{$name} = \(my $str = '') unless $self->{slots}{$name};
  return $self->{slots}{$name};
}

sub _tie_args {
  my ($self, $name) = @_;
  return {
    slot_name    => $name,
    combined_ref => $self->{combined},
    output_ref   => $self->_slot_ref($name),
  };
}


sub clear_slot {
  my ($self, $slot_name) = @_;
  ${ $self->_slot_ref($slot_name) } = '';
  return;
}


sub fh {
  my ($self, $name) = @_;

  my $sym = Symbol::gensym;
  my ($class, @rest) = $self->_tie_fh_args($name);
  tie *$sym, $class, @rest;
  return $sym;
}

sub TIEHANDLE {
  my ($self, @args) = @_;
  my ($class, @rest) = $self->_tie_fh_args(@args);

  return $class->TIEHANDLE(@rest);
}

sub _tie_fh_args {
  my ($self, $name) = @_;
  return ('IO::TieCombine::Handle', $self->_tie_args($name));
}


sub scalar_ref {
  my ($self, $name) = @_;
  my ($class, @rest) = $self->_tie_scalar_args($name);
  tie my($tie), $class, @rest;
  return \$tie;
}

sub TIESCALAR {
  my ($self, @args) = @_;
  my ($class, @rest) = $self->_tie_scalar_args(@args);

  return $class->TIESCALAR(@rest);
}

sub _tie_scalar_args {
  my ($self, $name) = @_;
  return ('IO::TieCombine::Scalar', $self->_tie_args($name));
}


sub callback {
  my ($self, $name) = @_;
  my $slot = $self->_slot_ref($name);
  return sub {
    my ($value) = @_;

    ${ $slot             } .= $value;
    ${ $self->{combined} } .= $value;
  }
}

1;

__END__
=pod

=head1 NAME

IO::TieCombine - produce tied (and other) separate but combined variables

=head1 VERSION

version 1.001

=head1 SYNOPSIS

First, we set up a bunch of access points:

  my $hub = IO::TieCombine->new;

  my $str_ref  = $hub->scalar_ref('x');
  my $fh       = $hub->fh('x');
  my $callback = $hub->callback('x');

  tie my $scalar, $hub, 'x';
  tie local *STDOUT, $hub, 'x';

  tie local *STDERR, $hub, 'err';

Then we write to things:

  $$str_ref .= 'And ';
  print $fh "now ";
  $callback->('for ');
  $scalar .= 'something ';
  print "completely ";
  warn "different.\n";

And then:

  $hub->combined_contents;    # And now for something completely different.
  $hub->slot_contents('x');   # And now for something completely
  $hub->slot_contents('err'); # different.

=head1 METHODS

=head2 new

The constructor takes no arguments.

=head2 combined_contents

This method returns the contents of all collected data.

=head2 slot_contents

  my $str = $hub->slot_contents( $slot_name );

This method returns the contents of all collected data for the named slot.

=head2 clear_slot

  $hub->clear_slot( $slot_name );

This sets the slot back to an empty string.

=head2 fh

  my $fh = $hub->fh( $slot_name );

This method returns a reference to a tied filehandle.  When printed to, output
is collected in the named slot.

=head2 scalar_ref

  my $str_ref = $hub->scalar_ref( $slot_name );

This method returns a reference to scalar.  When appended to, the new content
is collected in the named slot.  Attempting to alter the string other than by
adding new content to its end will result in an exception.

=head2 callback

  my $code = $hub->callback( $slot_name );

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

