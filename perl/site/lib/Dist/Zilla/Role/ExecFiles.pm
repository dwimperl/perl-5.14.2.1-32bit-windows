package Dist::Zilla::Role::ExecFiles;
{
  $Dist::Zilla::Role::ExecFiles::VERSION = '4.300007';
}
# ABSTRACT: something that finds files to install as executables
use Moose::Role;
with 'Dist::Zilla::Role::FileFinder';

use namespace::autoclean;

requires 'dir';

sub find_files {
  my ($self) = @_;

  my $dir = $self->dir;
  my $files = $self->zilla->files->grep(sub { index($_->name, "$dir/") == 0 });
}

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::ExecFiles - something that finds files to install as executables

=head1 VERSION

version 4.300007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

