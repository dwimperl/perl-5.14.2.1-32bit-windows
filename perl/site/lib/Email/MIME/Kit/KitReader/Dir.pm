package Email::MIME::Kit::KitReader::Dir;
BEGIN {
  $Email::MIME::Kit::KitReader::Dir::VERSION = '2.102010';
}
use Moose;
with 'Email::MIME::Kit::Role::KitReader';
# ABSTRACT: read kit entries out of a directory

use File::Spec;

# cache sometimes
sub get_kit_entry {
  my ($self, $path) = @_;
  
  my $fullpath = File::Spec->catfile($self->kit->source, $path);

  open my $fh, '<', $fullpath or die "can't open $fullpath for reading: $!";
  my $content = do { local $/; <$fh> };

  return \$content;
}

1;

__END__
=pod

=head1 NAME

Email::MIME::Kit::KitReader::Dir - read kit entries out of a directory

=head1 VERSION

version 2.102010

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

