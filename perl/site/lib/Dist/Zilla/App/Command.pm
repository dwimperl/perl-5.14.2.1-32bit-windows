use strict;
use warnings;
package Dist::Zilla::App::Command;
{
  $Dist::Zilla::App::Command::VERSION = '4.300007';
}
# ABSTRACT: base class for dzil commands
use App::Cmd::Setup -command;
use Moose::Autobox;


sub zilla {
  return $_[0]->app->zilla;
}


sub log {
  $_[0]->app->chrome->logger->log($_[1]);
}

1;

__END__
=pod

=head1 NAME

Dist::Zilla::App::Command - base class for dzil commands

=head1 VERSION

version 4.300007

=head1 METHODS

=head2 zilla

This returns the Dist::Zilla object in use by the command.  If none has yet
been constructed, one will be by calling C<< Dist::Zilla->from_config >>.

(This method just delegates to the Dist::Zilla::App object!)

=head2 log

This method calls the C<log> method of the application's chrome.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

