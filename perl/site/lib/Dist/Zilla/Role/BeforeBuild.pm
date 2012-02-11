package Dist::Zilla::Role::BeforeBuild;
{
  $Dist::Zilla::Role::BeforeBuild::VERSION = '4.300007';
}
# ABSTRACT: something that runs before building really begins
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;


requires 'before_build';

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::BeforeBuild - something that runs before building really begins

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

Plugins implementing this role have their C<before_build> method called
before any other plugins are consulted.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

