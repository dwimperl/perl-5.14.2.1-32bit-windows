package Dist::Zilla::MVP::Reader::Perl;
{
  $Dist::Zilla::MVP::Reader::Perl::VERSION = '4.300007';
}
use Moose;
extends 'Config::MVP::Reader';
with qw(Config::MVP::Reader::Findable::ByExtension);
# ABSTRACT: the reader for dist.pl files

use namespace::autoclean;


sub default_extension { 'pl' }

sub read_into_assembler {
  my ($self, $location, $asm) = @_;

  my @input = do $location;
  while (@input and ! ref $input[0]) {
    my ($key, $value) = (shift(@input), shift(@input));
    $asm->add_value($key => $value);
  }

  my $plugins = shift @input;

  confess "too much input" if @input;

  while (my ($ident, $arg) = splice @$plugins, 0, 2) {
    unless (ref $arg) {
      unshift @$plugins, $arg;
      $arg = [];
    }

    my ($moniker, $name) = ref $ident ? @$ident : (($ident) x 2);
    $asm->change_section($moniker, $name);
    my @to_iter = ref $arg eq 'HASH' ? %$arg : @$arg;
    while (my ($key, $value) = splice @to_iter, 0, 2) {
      $asm->add_value($key, $value);
    }
  }

  # should be done ... elsewhere? -- rjbs, 2009-08-24
  $self->assembler->end_section if $self->assembler->current_section;

  return $self->assembler->sequence;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::MVP::Reader::Perl - the reader for dist.pl files

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

Dist::Zilla::Config reads in the F<dist.pl> file for a distribution.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

