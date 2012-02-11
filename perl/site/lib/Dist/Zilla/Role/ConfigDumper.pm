package Dist::Zilla::Role::ConfigDumper;
{
  $Dist::Zilla::Role::ConfigDumper::VERSION = '4.300007';
}
# ABSTRACT: something that can dump its (public, simplified) configuraiton
use Moose::Role;

use namespace::autoclean;

sub dump_config { return {}; }

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::ConfigDumper - something that can dump its (public, simplified) configuraiton

=head1 VERSION

version 4.300007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

