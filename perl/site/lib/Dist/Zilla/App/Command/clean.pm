use strict;
use warnings;
package Dist::Zilla::App::Command::clean;
{
  $Dist::Zilla::App::Command::clean::VERSION = '4.300007';
}
# ABSTRACT: clean up after build, test, or install
use Dist::Zilla::App -command;


sub abstract { 'clean up after build, test, or install' }

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->zilla->clean;
}

1;

__END__
=pod

=head1 NAME

Dist::Zilla::App::Command::clean - clean up after build, test, or install

=head1 VERSION

version 4.300007

=head1 SYNOPSIS

  dzil clean

This command removes some files that are created during build, test, and
install.  It's a very thin layer over the C<L<clean|Dist::Zilla/clean>> method
on the Dist::Zilla object.  The documentation for that method gives more
information about the files that will be removed.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

