use strict;
use warnings;
package Dist::Zilla::App::Command::install;
{
  $Dist::Zilla::App::Command::install::VERSION = '4.300007';
}
# ABSTRACT: install your dist
use Dist::Zilla::App -command;

sub abstract { 'install your dist' }


sub opt_spec {
  [ 'install-command=s', 'command to run to install (e.g. "cpan .")' ],
}


sub execute {
  my ($self, $opt, $arg) = @_;

  $self->zilla->install({
    $opt->install_command
      ? (install_command => [ $opt->install_command ])
      : (),
  });
}

1;

__END__
=pod

=head1 NAME

Dist::Zilla::App::Command::install - install your dist

=head1 VERSION

version 4.300007

=head1 SYNOPSIS

Installs your distribution using a specified command.

    dzil install [--install-command="cmd"]

=head1 EXAMPLE

    $ dzil install
    $ dzil install --install-command="cpan ."

=head1 OPTIONS

=head2 --install-command

This defines what command to run after building the dist in the dist dir.

Any value that works with L<C<system>|perlfunc/system> is accepted.

If not specified, calls (roughly):

    perl -MCPAN -einstall "."

For more information, look at the L<install|Dist::Zilla/install> method in
Dist::Zilla.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

