package Dist::Zilla::Plugin::MetaResources;
{
  $Dist::Zilla::Plugin::MetaResources::VERSION = '4.300007';
}

# ABSTRACT: provide arbitrary "resources" for distribution metadata
use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use namespace::autoclean;


has resources => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);

sub BUILDARGS {
  my ($class, @arg) = @_;
  my %copy = ref $arg[0] ? %{ $arg[0] } : @arg;

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  if (exists $copy{bugtracker}) {
    my $tracker = delete $copy{bugtracker};
    $copy{bugtracker}{web} = $tracker;
  }

  if (exists $copy{repository}) {
    my $repo = delete $copy{repository};
    $copy{repository}{url} = $repo;
  }

  for my $multi (qw( bugtracker repository )) {
    for my $key (grep { /^\Q$multi\E\./ } keys %copy) {
      my $subkey = (split /\./, $key, 2)[1];
      $copy{$multi}{$subkey} = delete $copy{$key};
    }
  }

  return {
    zilla       => $zilla,
    plugin_name => $name,
    resources   => \%copy,
  };
}

sub metadata {
  my ($self) = @_;

  return { resources => $self->resources };
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::MetaResources - provide arbitrary "resources" for distribution metadata

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This plugin adds resources entries to the distribution's metadata.

  [MetaResources]
  homepage          = http://example.com/~dude/project.asp
  bugtracker.web    = http://rt.cpan.org/NoAuth/Bugs.html?Dist=Project
  bugtracker.mailto = bug-project@rt.cpan.org
  repository.url    = git://github.com/dude/project.git
  repository.web    = http://github.com/dude/project
  repository.type   = git

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

