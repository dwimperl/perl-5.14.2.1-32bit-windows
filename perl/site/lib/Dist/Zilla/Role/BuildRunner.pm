package Dist::Zilla::Role::BuildRunner;
{
  $Dist::Zilla::Role::BuildRunner::VERSION = '4.300007';
}
# ABSTRACT: something used as a delegating agent during 'dzil run'
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;


requires 'build';

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::BuildRunner - something used as a delegating agent during 'dzil run'

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

Plugins implementing this role have their C<build> method called during
C<dzil run>.  It's passed the root directory of the build test dir.

=head1 REQUIRED METHODS

=head2 build

This method will throw an exception on failure.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

