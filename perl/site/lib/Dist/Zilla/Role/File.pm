package Dist::Zilla::Role::File;
{
  $Dist::Zilla::Role::File::VERSION = '4.300007';
}
# ABSTRACT: something that can act like a file
use Moose::Role;

use Moose::Util::TypeConstraints;

use namespace::autoclean;


has name => (
  is   => 'rw',
  isa  => 'Str', # Path::Class::File?
  required => 1,
);


has added_by => (
  is => 'ro',
);


my $safe_file_mode = subtype(
  as 'Int',
  where   { not( $_ & 0002) },
  message { "file mode would be world-writeable" }
);

has mode => (
  is      => 'rw',
  isa     => $safe_file_mode,
  default => 0644,
);

requires 'content';

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::File - something that can act like a file

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This role describes a file that may be written into the shipped distribution.

=head1 ATTRIBUTES

=head2 name

This is the name of the file to be written out.

=head2 added_by

This is a string describing when and why the file was added to the
distribution.  It will generally be set by a plugin implementing the
L<FileInjector|Dist::Zilla::Role::FileInjector> role.

=head2 mode

This is the mode with which the file should be written out.  It's an integer
with the usual C<chmod> semantics.  It defaults to 0644.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

