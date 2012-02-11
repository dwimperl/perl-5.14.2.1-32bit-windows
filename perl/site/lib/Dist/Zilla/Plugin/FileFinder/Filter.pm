package Dist::Zilla::Plugin::FileFinder::Filter;
{
  $Dist::Zilla::Plugin::FileFinder::Filter::VERSION = '4.300007';
}
use Moose;
with(
  'Dist::Zilla::Role::FileFinder',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [],
  },
);
# ABSTRACT: filter matches from other FileFinders

use namespace::autoclean;


use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(ArrayRef RegexpRef Str);

{
  my $type = subtype as ArrayRef[RegexpRef];
  coerce $type, from ArrayRef[Str], via { [map { qr/$_/ } @$_] };


  has skips => (
    is      => 'ro',
    isa     => $type,
    coerce  => 1,
    default => sub { [] },
  );
}

sub mvp_aliases { +{ qw(
  skip     skips
) } }

sub mvp_multivalue_args { qw(skips) }

sub find_files {
  my $self = shift;

  my $files = $self->found_files;

  foreach my $re (@{ $self->skips }) {
    @$files = grep { $_->name !~ $re } @$files;
  }

  $self->log_debug("No files found") unless @$files;
  $self->log_debug("Found " . $_->name) for @$files;

  $files;
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Dist::Zilla::Plugin::FileFinder::Filter - filter matches from other FileFinders

=head1 VERSION

version 4.300007

=head1 SYNOPSIS

In your F<dist.ini>:

  [FileFinder::Filter / MyFiles]
  finder = :InstallModules ; find files from :InstallModules
  finder = :ExecFiles      ; or :ExecFiles
  skip  = ignore           ; that don't have "ignore" in the path

=head1 DESCRIPTION

FileFinder::Filter is a L<FileFinder|Dist::Zilla::Role::FileFinder> that
selects files by filtering the selections of other FileFinders.

You specify one or more FileFinders to generate the initial list of
files.  Any file whose pathname matches any of the C<skip> regexs is
removed from that list.

=head1 ATTRIBUTES

=head2 finder

A FileFinder to supply the initial list of files.
May occur multiple times.

=head2 skip

The pathname must I<not> match any of these regular expressions.
May occur multiple times.

=head1 CREDITS

This plugin was originally contributed by Christopher J. Madsen.

=for Pod::Coverage mvp_aliases
mvp_multivalue_args
find_files

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

