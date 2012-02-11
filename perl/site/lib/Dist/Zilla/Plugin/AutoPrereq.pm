package Dist::Zilla::Plugin::AutoPrereq;
{
  $Dist::Zilla::Plugin::AutoPrereq::VERSION = '4.300007';
}
use Moose;
extends 'Dist::Zilla::Plugin::AutoPrereqs';
# ABSTRACT: (DEPRECATED) the old name for Dist::Zilla::Plugin::AutoPrereqs

use namespace::autoclean;

before register_component => sub {
  die "[AutoPrereq] will be removed in Dist::Zilla v5; replace it with [AutoPrereqs] (note the 's')\n"
    if Dist::Zilla->VERSION >= 5;

  warn "!!! [AutoPrereq] will be removed in Dist::Zilla v5; replace it with [AutoPrereqs] (note the 's')\n";
};

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::AutoPrereq - (DEPRECATED) the old name for Dist::Zilla::Plugin::AutoPrereqs

=head1 VERSION

version 4.300007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

