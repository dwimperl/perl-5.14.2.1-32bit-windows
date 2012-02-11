package Dist::Zilla::Types;
{
  $Dist::Zilla::Types::VERSION = '4.300007';
}
# ABSTRACT: dzil-specific type library

use namespace::autoclean;


use MooseX::Types -declare => [qw(License OneZero YesNoStr)];
use MooseX::Types::Moose qw(Str Int);

subtype License, as class_type('Software::License');

subtype OneZero, as Str, where { $_ eq '0' or $_ eq '1' };

subtype YesNoStr, as Str, where { /\A(?:y|ye|yes)\Z/i or /\A(?:n|no)\Z/i };

coerce OneZero, from YesNoStr, via { /\Ay/i ? 1 : 0 };

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Types - dzil-specific type library

=head1 VERSION

version 4.300007

=head1 OVERVIEW

This library provides L<MooseX::Types> types for use by Dist::Zilla.  These
types are not (yet?) for public consumption, and you should not rely on them.

Dist::Zilla uses a number of types found in L<MooseX::Types::Perl>.  Maybe
that's what you want.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

