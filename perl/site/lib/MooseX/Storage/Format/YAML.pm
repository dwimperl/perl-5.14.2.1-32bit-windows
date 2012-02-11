package MooseX::Storage::Format::YAML;
use Moose::Role;

# When I add YAML::LibYAML
# Tests break because tye YAML is invalid...?
# -dcp

use YAML::Any qw(Load Dump);

our $VERSION   = '0.30';
our $AUTHORITY = 'cpan:STEVAN';

requires 'pack';
requires 'unpack';

sub thaw {
    my ( $class, $yaml, @args ) = @_;
    $class->unpack( Load($yaml), @args );
}

sub freeze {
    my ( $self, @args ) = @_;
    Dump( $self->pack(@args) );
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

MooseX::Storage::Format::YAML - A YAML serialization role

=head1 SYNOPSIS

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage('format' => 'YAML');

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  1;

  my $p = Point->new(x => 10, y => 10);

  ## methods to freeze/thaw into
  ## a specified serialization format
  ## (in this case YAML)

  # pack the class into a YAML string
  $p->freeze();

  # ----
  # __CLASS__: "Point"
  # x: 10
  # y: 10

  # unpack the JSON string into a class
  my $p2 = Point->thaw(<<YAML);
  ----
  __CLASS__: "Point"
  x: 10
  y: 10
  YAML

=head1 METHODS

=over 4

=item B<freeze>

=item B<thaw ($yaml)>

=back

=head2 Introspection

=over 4

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Chris Prather E<lt>chris.prather@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


