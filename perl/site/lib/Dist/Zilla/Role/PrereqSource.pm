package Dist::Zilla::Role::PrereqSource;
{
  $Dist::Zilla::Role::PrereqSource::VERSION = '4.300007';
}
# ABSTRACT: something that registers prerequisites
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;


requires 'register_prereqs';

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::PrereqSource - something that registers prerequisites

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

PrereqSource plugins have a C<register_prereqs> method that should register
prereqs with the Dist::Zilla object.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

