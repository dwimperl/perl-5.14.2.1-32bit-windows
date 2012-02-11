package Dist::Zilla::Plugin::ModuleShareDirs;
{
  $Dist::Zilla::Plugin::ModuleShareDirs::VERSION = '4.300007';
}
# ABSTRACT: install a directory's contents as module-based "ShareDir" content
use Moose;

use namespace::autoclean;

use Moose::Autobox;


has _module_map => (
  is   => 'ro',
  isa  => 'HashRef',
  default => sub { {} },
);

sub find_files {
  my ($self) = @_;
  my $modmap = $self->_module_map;
  my @files;

  for my $mod ( keys %$modmap ) {
    my $dir = $modmap->{$mod};
    my $mod_files = $self->zilla->files->grep(
      sub { index($_->name, "$dir/") == 0 }
    );
    push @files, @$mod_files;
  }

  return \@files;
}

sub share_dir_map {
  my ($self) = @_;
  my $modmap = $self->_module_map;

  return unless keys %$modmap;
  return { module => $modmap };
}

sub BUILDARGS {
  my ($class, @arg) = @_;
  my %copy = ref $arg[0] ? %{$arg[0]} : @arg;

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  return {
    zilla => $zilla,
    plugin_name => $name,
    _module_map => \%copy,
  }
}

with 'Dist::Zilla::Role::ShareDir';
__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::ModuleShareDirs - install a directory's contents as module-based "ShareDir" content

=head1 VERSION

version 4.300007

=head1 SYNOPSIS

In your F<dist.ini>:

  [ModuleShareDirs]
  Foo::Bar = shares/foo_bar
  Foo::Baz = shares/foo_baz

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

