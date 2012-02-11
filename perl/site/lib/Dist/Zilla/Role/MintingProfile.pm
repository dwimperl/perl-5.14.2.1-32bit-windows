package Dist::Zilla::Role::MintingProfile;
{
  $Dist::Zilla::Role::MintingProfile::VERSION = '4.300007';
}
# ABSTRACT: something that can find a minting profile dir
use Moose::Role;

use namespace::autoclean;

use File::ShareDir;
use Path::Class;


requires 'profile_dir';

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::MintingProfile - something that can find a minting profile dir

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

Plugins implementing this role should provide C<profile_dir> method, which,
given a minting profile name, returns its directory.

The minting profile is a directory, containing arbitrary files used during
creation of new distribution. Among other things notably, it should contain the
'profile.ini' file, listing the plugins used for minter initialization.

The default implementation C<profile_dir> looks in the module's
L<ShareDir|File::ShareDir>.

After installing your profile, users will be able to start a new distribution,
based on your profile with the:

  $ dzil new -P Provider -p profile_name Distribution::Name

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

