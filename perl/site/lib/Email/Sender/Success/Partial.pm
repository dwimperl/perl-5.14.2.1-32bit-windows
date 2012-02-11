package Email::Sender::Success::Partial;
{
  $Email::Sender::Success::Partial::VERSION = '0.110003';
}
use Moose;
extends 'Email::Sender::Success';
# ABSTRACT: a report of partial success when delivering


use Email::Sender::Failure::Multi;

has failure => (
  is  => 'ro',
  isa => 'Email::Sender::Failure::Multi',
  required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Email::Sender::Success::Partial - a report of partial success when delivering

=head1 VERSION

version 0.110003

=head1 DESCRIPTION

These objects indicate that some deliver was accepted for some recipients and
not others.  The success object's C<failure> attribute will return a
L<Email::Sender::Failure::Multi> describing which parts of the delivery failed.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

