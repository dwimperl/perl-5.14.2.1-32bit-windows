package Dist::Zilla::Role::MetaProvider;
{
  $Dist::Zilla::Role::MetaProvider::VERSION = '4.300007';
}
# ABSTRACT: something that provides metadata (for META.yml/json)
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;


requires 'metadata';

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::MetaProvider - something that provides metadata (for META.yml/json)

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This role provides data to merge into the distribution metadata.

=head1 METHODS

=head2 metadata

This method (which must be provided by classes implementing this role)
returns a hashref of data to be (deeply) merged together with pre-existing
metadata.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

