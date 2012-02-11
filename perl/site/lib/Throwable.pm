package Throwable;
BEGIN {
  $Throwable::VERSION = '0.102080';
}
use Moose::Role 0.87;
# ABSTRACT: a role for classes that can be thrown


has 'previous_exception' => (
  is       => 'ro',
  init_arg => undef,
  default  => sub {
    return unless defined $@ and (ref $@ or length $@);
    return $@;
  },
);


sub throw {
  my ($inv) = shift;

  if (blessed $inv) {
    confess "throw called on Throwable object with arguments" if @_;
    die $inv;
  }

  my $throwable = $inv->new(@_);
  die $throwable;
}

no Moose::Role;
1;

__END__
=pod

=head1 NAME

Throwable - a role for classes that can be thrown

=head1 VERSION

version 0.102080

=head1 SYNOPSIS

  package Redirect;
  use Moose;
  with 'Throwable';

  has url => (is => 'ro');

...then later...

  Redirect->throw({ url => $url });

=head1 DESCRIPTION

Throwable is a role for classes that are meant to be thrown as exceptions to
standard program flow.  It is very simple and does only two things: saves any
previous value for C<$@> and calls C<die $self>.

=head1 ATTRIBUTES

=head2 previous_exception

This attribute is created automatically, and stores the value of C<$@> when the
Throwable object is created.

=head1 METHODS

=head2 throw

  Something::Throwable->throw({ attr => $value });

This method will call new, passing all arguments along to new, and will then
use the created object as the only argument to C<die>.

If called on an object that does Throwable, the object will be rethrown.

=head1 AUTHORS

=over 4

=item *

Ricardo SIGNES <rjbs@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

