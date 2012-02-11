package Dist::Zilla::PluginBundle::FakeClassic;
{
  $Dist::Zilla::PluginBundle::FakeClassic::VERSION = '4.300007';
}
# ABSTRACT: build something more or less like a "classic" CPAN dist
use Moose;
extends 'Dist::Zilla::PluginBundle::Classic';

use namespace::autoclean;

use Moose::Autobox;

around bundle_config => sub {
  my ($orig, $self, $arg) = @_;

  my @config = $self->$orig($arg);

  for my $i (0 .. $#config) {
    if ($config[ $i ][1] eq 'Dist::Zilla::Plugin::UploadToCPAN') {
      require Dist::Zilla::Plugin::FakeRelease;
      $config[ $i ] = [
        "$arg->{name}/FakeRelease",
        'Dist::Zilla::Plugin::FakeRelease',
        $config[ $i ][2]
      ];
    }
  }

  return @config;
};

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::PluginBundle::FakeClassic - build something more or less like a "classic" CPAN dist

=head1 VERSION

version 4.300007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

