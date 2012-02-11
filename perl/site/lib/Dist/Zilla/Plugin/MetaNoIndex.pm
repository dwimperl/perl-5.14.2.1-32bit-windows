package Dist::Zilla::Plugin::MetaNoIndex;
{
  $Dist::Zilla::Plugin::MetaNoIndex::VERSION = '4.300007';
}
# ABSTRACT: Stop CPAN from indexing stuff

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use namespace::autoclean;


my %ATTR_ALIAS = (
  directories => [ qw(directory dir folder) ],
  files       => [ qw(file) ],
  packages    => [ qw(package class module) ],
  namespaces  => [ qw(namespace) ],
);

sub mvp_aliases {
  my %alias_for;
  
  for my $key (keys %ATTR_ALIAS) {
    $alias_for{ $_ } = $key for @{ $ATTR_ALIAS{$key} };
  }

  return \%alias_for;
}

sub mvp_multivalue_args { return keys %ATTR_ALIAS }


for my $attr (keys %ATTR_ALIAS) {
  has $attr => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    init_arg  => $attr,
    predicate => "_has_$attr",
  );
}


sub metadata {
  my $self = shift;
  return {
    no_index => {
      map  {; my $reader = $_->[0];  ($_->[1] => $self->$reader) }
      grep {; my $pred   = "_has_$_->[0]"; $self->$pred }
      map  {; [ $_ => $ATTR_ALIAS{$_}[0] ] }
      keys %ATTR_ALIAS
    }
  };
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::MetaNoIndex - Stop CPAN from indexing stuff

=head1 VERSION

version 4.300007

=head1 SYNOPSIS

In your F<dist.ini>:

  [MetaNoIndex]

  directory = t/author
  directory = examples

  file = lib/Foo.pm

  package = My::Module

  namespace = My::Module

=head1 DESCRIPTION

This plugin allows you to prevent PAUSE/CPAN from indexing files you don't
want indexed. This is useful if you build test classes or example classes
that are used for those purposes only, and are not part of the distribution.
It does this by adding a C<no_index> block to your F<META.json> (or
F<META.yml>) file in your distribution.

=head1 ATTRIBUTES

=head2 directories

Exclude folders and everything in them, for example: F<author.t>

Aliases: C<folder>, C<dir>, C<directory>

=head2 files

Exclude a specific file, for example: F<lib/Foo.pm>

Alias: C<file>

=head2 packages

Exclude by package name, for example: C<My::Package>

Aliases: C<class>, C<module>, C<package>

=head2 namespaces

Exclude everything under a specific namespace, for example: C<My::Package>

Alias: C<namespace>

B<NOTE:> This will not exclude the package C<My::Package>, only everything
under it like C<My::Package::Foo>.

=head1 METHODS

=head2 metadata

Returns a reference to a hash containing the distribution's no_index metadata.

=encoding utf8

=for Pod::Coverage mvp_aliases mvp_multivalue_args

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

