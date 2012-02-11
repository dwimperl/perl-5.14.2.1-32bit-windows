package Dist::Zilla::Role::AfterMint;
{
  $Dist::Zilla::Role::AfterMint::VERSION = '4.300007';
}
# ABSTRACT: something that runs after minting is mostly complete
use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use namespace::autoclean;


requires 'after_mint';

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::AfterMint - something that runs after minting is mostly complete

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

Plugins implementing this role have their C<after_mint> method called once all
the files have been written out.  It is passed a hashref with the following
data:

  mint_root - the directory in which the dist was minted

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

