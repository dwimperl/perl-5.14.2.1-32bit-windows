package Email::MIME::Kit::Role::KitReader;
BEGIN {
  $Email::MIME::Kit::Role::KitReader::VERSION = '2.102010';
}
use Moose::Role;
with 'Email::MIME::Kit::Role::Component';
# ABSTRACT: things that can read kit contents


requires 'get_kit_entry';

no Moose::Role;
1;

__END__
=pod

=head1 NAME

Email::MIME::Kit::Role::KitReader - things that can read kit contents

=head1 VERSION

version 2.102010

=head1 IMPLEMENTING

This role also performs L<Email::MIME::Kit::Role::Component>.

Classes implementing this role must provide a C<get_kit_entry> method.  It will
be called with one parameter, the name of a path to an entry in the kit.  It
should return a reference to a scalar holding the contents of the named entry.
If no entry is found, it should raise an exception.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

