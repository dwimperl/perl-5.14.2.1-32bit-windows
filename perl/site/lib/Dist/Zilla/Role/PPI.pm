package Dist::Zilla::Role::PPI;
{
  $Dist::Zilla::Role::PPI::VERSION = '4.300007';
}
# ABSTRACT: a role for plugins which use PPI
use Moose::Role;

use Moose::Util::TypeConstraints;

use namespace::autoclean;

use Digest::MD5 qw(md5);


my %CACHE;

sub ppi_document_for_file {
  my ($self, $file) = @_;

  my $content = $file->content;

  # We cache on the MD5 checksum to detect if the document has been modified
  # by some other plugin since it was last parsed, our document is invalid.
  my $md5 = md5($content);
  return $CACHE{$md5} if $CACHE{$md5};

  my $document = PPI::Document->new(\$content)
    or Carp::croak(PPI::Document->errstr);

  return $CACHE{$md5} = $document;
}


sub save_ppi_document_to_file {
  my ($self, $document, $file) = @_;

  my $new_content = $document->serialize;

  $CACHE{ md5($new_content) } = $document;

  $file->content($new_content);
}


sub document_assigns_to_variable {
  my ($self, $document, $variable) = @_;

  my $finder = sub {
    my $node = $_[1];
    return 1 if $node->isa('PPI::Statement') && $node->content =~ /\Q$variable\E\s*=/sm;
    return 0;
  };

  my $rv = $document->find_any($finder);
  Carp::croak($document->errstr) unless defined $rv;

  return $rv;
}

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::PPI - a role for plugins which use PPI

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This role provides some common utilities for plugins which use PPI

=head1 METHODS

=head2 ppi_document_for_file

  my $document = $self->ppi_document_for_file($file);

Given a dzil file object (anything that does L<Dist::Zilla::Role::File>), this
method returns a new L<PPI::Document> for that file's content.

Internally, this method caches these documents. If multiple plugins want a
document for the same file, this avoids reparsing it.

=head2 save_ppi_document_to_file

  my $document = $self->save_ppi_document_to_file($document,$file);

Given a L<PPI::Document> and a dzil file object (anything that does
L<Dist::Zilla::Role::File>), this method saves the serialized document in the
file.

It also updates the internal PPI document cache with the new document.

=head2 document_assigns_to_variable

  if( $self->ppi_document_for_file($document, '$FOO')) { ... }

This method returns true if the document assigns to the given variable.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

