package Dist::Zilla::Plugin::ExecDir;
{
  $Dist::Zilla::Plugin::ExecDir::VERSION = '4.300007';
}
# ABSTRACT: install a directory's contents as executables
use Moose;

use namespace::autoclean;

use Moose::Autobox;


has dir => (
  is   => 'ro',
  isa  => 'Str',
  default => 'bin',
);

sub find_files {
  my ($self) = @_;

  my $dir = $self->dir;
  my $files = $self->zilla->files->grep(sub { index($_->name, "$dir/") == 0 });
}

with 'Dist::Zilla::Role::ExecFiles';
__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::ExecDir - install a directory's contents as executables

=head1 VERSION

version 4.300007

=head1 SYNOPSIS

In your F<dist.ini>:

  [ExecDir]
  dir = scripts

If no C<dir> is provided, the default is F<bin>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

