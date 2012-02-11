package Config::MVP::Reader::Findable::ByExtension;
BEGIN {
  $Config::MVP::Reader::Findable::ByExtension::VERSION = '2.200001';
}
use Moose::Role;
# ABSTRACT: a Findable Reader that looks for files by extension

with qw(Config::MVP::Reader::Findable);

use File::Spec;


requires 'default_extension';


sub refined_location {
  my ($self, $location) = @_;

  my $candidate_name = "$location." . $self->default_extension;
  return unless -r $candidate_name and -f _;
  return $candidate_name;
}

no Moose::Role;
1;

__END__
=pod

=head1 NAME

Config::MVP::Reader::Findable::ByExtension - a Findable Reader that looks for files by extension

=head1 VERSION

version 2.200001

=head1 METHODS

=head2 default_extension

This method, B<which must be composed by classes including this role>, returns
the default extension used by files in the format this reader can read.

When the Finder tries to find configuration, it have a directory root and a
basename.  Each (Findable) reader that it tries in turn will look for a file
F<basename.extension> in the root directory.  If exactly one file is found,
that file is read.

=head2 refined_location

This role provides a default implementation of the
L<C<refined_location>|Config::MVP::Reader::Findable/refined_location> method
required by Config::MVP::Reader.  It will return a filename based on the
original location, if a file exists matching that location plus the reader's
C<default_extension>.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

