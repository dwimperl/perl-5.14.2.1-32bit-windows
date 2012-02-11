package Dist::Zilla::Role::BuildPL;
{
  $Dist::Zilla::Role::BuildPL::VERSION = '4.300007';
}
use Moose::Role;

with qw(
  Dist::Zilla::Role::InstallTool
  Dist::Zilla::Role::BuildRunner
  Dist::Zilla::Role::TestRunner
);

use namespace::autoclean;

sub build {
  my $self = shift;

  system $^X, 'Build.PL' and die "error with Build.PL\n";
  system $^X, 'Build'    and die "error running $^X Build\n";

  return;
}

sub test {
  my ($self, $target) = @_;

  $self->build;
  my @testing = $self->zilla->logger->get_debug ? '--verbose' : ();
  system $^X, 'Build', 'test', @testing and die "error running $^X Build test\n";

  return;
}

1;

# ABSTRACT: Common ground for Build.PL based builders



__END__
=pod

=head1 NAME

Dist::Zilla::Role::BuildPL - Common ground for Build.PL based builders

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This role is a helper for Build.PL based installers. It implements the L<Dist::Zilla::Plugin::BuildRunner> and L<Dist::Zilla::Plugin::TestRunner> roles, and requires you to implement the L<Dist::Zilla::Plugin::PrereqSource> and L<Dist::Zilla::Plugin::InstallTool> roles yourself.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

