package Dist::Zilla::File::InMemory;
{
  $Dist::Zilla::File::InMemory::VERSION = '4.300007';
}
# ABSTRACT: a file that you build entirely in memory
use Moose;

use namespace::autoclean;


has content => (
  is  => 'rw',
  isa => 'Str',
  required => 1,
);

with 'Dist::Zilla::Role::File';
__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::File::InMemory - a file that you build entirely in memory

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This represents a file created in memory -- it's not much more than a glorified
string.  It has a read/write C<content> attribute that holds the octets that
will be written to disk.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

