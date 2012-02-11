package Role::Identifiable::HasIdent;
BEGIN {
  $Role::Identifiable::HasIdent::VERSION = '0.005';
}
use Moose::Role;
# ABSTRACT: a thing with an ident attribute


has ident => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

no Moose::Role;
1;

__END__
=pod

=head1 NAME

Role::Identifiable::HasIdent - a thing with an ident attribute

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This is an incredibly simple role.  It adds a required C<ident> attribute that
stores a simple string, meant to identify exceptions.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

