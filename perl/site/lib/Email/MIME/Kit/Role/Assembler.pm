package Email::MIME::Kit::Role::Assembler;
BEGIN {
  $Email::MIME::Kit::Role::Assembler::VERSION = '2.102010';
}
use Moose::Role;
with 'Email::MIME::Kit::Role::Component';
# ABSTRACT: things that assemble messages (or parts)


requires 'assemble';

no Moose::Role;
1;

__END__
=pod

=head1 NAME

Email::MIME::Kit::Role::Assembler - things that assemble messages (or parts)

=head1 VERSION

version 2.102010

=head1 IMPLEMENTING

This role also performs L<Email::MIME::Kit::Role::Component>.

Classes implementing this role must provide an C<assemble> method.  This method
will be passed a hashref of assembly parameters, and should return the fully
assembled Email::MIME object.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

