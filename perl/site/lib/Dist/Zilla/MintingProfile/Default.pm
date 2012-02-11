package Dist::Zilla::MintingProfile::Default;
{
  $Dist::Zilla::MintingProfile::Default::VERSION = '4.300007';
}
# ABSTRACT: Default minting profile provider
use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';

use namespace::autoclean;

use Dist::Zilla::Util;
use Path::Class;


around profile_dir => sub {
  my ($orig, $self, $profile_name) = @_;

  $profile_name ||= 'default';

  my $profile_dir = Dist::Zilla::Util->_global_config_root
                  ->subdir('profiles', $profile_name);

  return $profile_dir if -d $profile_dir;

  return $self->$orig($profile_name);
};

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::MintingProfile::Default - Default minting profile provider

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

Default minting profile provider.

This provider looks first in the F<~/.dzil/profiles/$profile_name> directory,
if not found it looks among the default profiles shipped with Dist::Zilla.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

