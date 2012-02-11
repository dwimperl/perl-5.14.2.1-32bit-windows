package Dist::Zilla::Plugin::PruneFiles;
{
  $Dist::Zilla::Plugin::PruneFiles::VERSION = '4.300007';
}
# ABSTRACT: prune arbirary files from the dist
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FilePruner';

use namespace::autoclean;


sub mvp_multivalue_args { qw(filenames matches) }
sub mvp_aliases { return { filename => 'filenames', match => 'matches' } }


has filenames => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);


has matches => (
  is   => 'ro',
  isa  => 'ArrayRef',
  default => sub { [] },
);

sub prune_files {
  my ($self) = @_;

  # never match (at least the filename characters)
  my $matches_regex = qr/\000/;

  $matches_regex = qr/$matches_regex|$_/ for ($self->matches->flatten);

  # \A\Q$_\E should also handle the `eq` check
  $matches_regex = qr/$matches_regex|\A\Q$_\E/ for ($self->filenames->flatten);

  for my $file ($self->zilla->files->flatten) {
    next unless $file->name =~ $matches_regex;

    $self->log_debug([ 'pruning %s', $file->name ]);

    $self->zilla->prune_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::PruneFiles - prune arbirary files from the dist

=head1 VERSION

version 4.300007

=head1 SYNOPSIS

This plugin allows you to explicitly prune some files from your
distribution. You can either specify the exact set of files (with the
"filenames" parameter) or provide the regular expressions to
check (using "match").

This is useful if another plugin (maybe a FileGatherer) adds a
bunch of files, and you only want a subset of them.

In your F<dist.ini>:

  [PruneFiles]
  filename = xt/release/pod-coverage.t ; pod coverage tests are for jerks
  filename = todo-list.txt             ; keep our secret plans to ourselves

  match     = ^test_data/*
  match     = ^test.cvs$

=head1 ATTRIBUTES

=head2 filenames

This is an arrayref of filenames to be pruned from the distribution.

=head2 matches

This is an arrayref of regular expressions and files matching any of them,
will be pruned from the distribution.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

