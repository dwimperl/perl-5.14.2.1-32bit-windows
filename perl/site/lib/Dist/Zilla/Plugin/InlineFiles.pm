package Dist::Zilla::Plugin::InlineFiles;
{
  $Dist::Zilla::Plugin::InlineFiles::VERSION = '4.300007';
}
# ABSTRACT: files in a data section
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;


use Sub::Exporter::ForMethods;
use Data::Section 0.004 # fixed header_re
  { installer => Sub::Exporter::ForMethods::method_installer },
  '-setup';
use Dist::Zilla::File::InMemory;

sub gather_files {
  my ($self) = @_;

  my $data = $self->merged_section_data;
  return unless $data and %$data;

  for my $name (keys %$data) {
    $self->add_file(
      Dist::Zilla::File::InMemory->new({
        name    => $name,
        content => ${ $data->{$name} },
      }),
    );
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::InlineFiles - files in a data section

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This plugin exists only to be extended, and gathers all files contained in its
data section and those of its ancestors.  For more information, see
L<Data::Section|Data::Section>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

