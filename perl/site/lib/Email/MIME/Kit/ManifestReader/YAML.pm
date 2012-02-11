package Email::MIME::Kit::ManifestReader::YAML;
BEGIN {
  $Email::MIME::Kit::ManifestReader::YAML::VERSION = '2.102010';
}
use Moose;
# ABSTRACT: read manifest.yaml files

with 'Email::MIME::Kit::Role::ManifestReader';
with 'Email::MIME::Kit::Role::ManifestDesugarer';

use YAML::XS ();

sub read_manifest {
  my ($self) = @_;

  my $yaml_ref = $self->kit->kit_reader->get_kit_entry('manifest.yaml');

  my ($content) = YAML::XS::Load($$yaml_ref);

  return $content;
}

no Moose;
1;

__END__
=pod

=head1 NAME

Email::MIME::Kit::ManifestReader::YAML - read manifest.yaml files

=head1 VERSION

version 2.102010

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

