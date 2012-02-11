package Email::MIME::Kit::Role::Component;
BEGIN {
  $Email::MIME::Kit::Role::Component::VERSION = '2.102010';
}
use Moose::Role;
# ABSTRACT: things that are kit components


has kit => (
  is  => 'ro',
  isa => 'Email::MIME::Kit',
  required => 1,
  weak_ref => 1,
);

no Moose::Role;
1;

__END__
=pod

=head1 NAME

Email::MIME::Kit::Role::Component - things that are kit components

=head1 VERSION

version 2.102010

=head1 DESCRIPTION

All (or most, anyway) components of an Email::MIME::Kit will perform this role.
Its primary function is to provide a C<kit> attribute that refers back to the
Email::MIME::Kit into which the component was installed.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

