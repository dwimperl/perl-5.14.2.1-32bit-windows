package Dist::Zilla::Role::Releaser;
{
  $Dist::Zilla::Role::Releaser::VERSION = '4.300007';
}
# ABSTRACT: something that makes a release of the dist
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;


requires 'release';

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::Releaser - something that makes a release of the dist

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

Plugins implementing this role have their C<release> method called when
releasing.  It's passed the distribution tarball to be released.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

