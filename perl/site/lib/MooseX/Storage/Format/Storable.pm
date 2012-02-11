
package MooseX::Storage::Format::Storable;
use Moose::Role;

use Storable ();

our $VERSION   = '0.30';
our $AUTHORITY = 'cpan:STEVAN';

requires 'pack';
requires 'unpack';

sub thaw {
    my ( $class, $stored, @args ) = @_;
    $class->unpack( Storable::thaw($stored), @args );
}

sub freeze {
    my ( $self, @args ) = @_;
    Storable::nfreeze( $self->pack(@args) );
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

MooseX::Storage::Format::Storable - A Storable serialization role

=head1 SYNOPSIS

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage('format' => 'Storable');

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  1;

  my $p = Point->new(x => 10, y => 10);

  ## methods to freeze/thaw into
  ## a specified serialization format

  # pack the class with Storable
  my $storable_data = $p->freeze();

  # unpack the storable data into the class
  my $p2 = Point->thaw($storable_data);

=head1 DESCRIPTION

This module will C<thaw> and C<freeze> Moose classes using Storable. It
uses C<Storable::nfreeze> by default so that it can be easily used
in IPC scenarios across machines or just locally.

One important thing to note is that this module does not mix well
with the IO modules. The structures that C<freeze> and C<thaw> deal with
are Storable's memory representation, and (as far as I know) that
is not easily just written onto a file. If you want file based
serialization with Storable, the please look at the
L<MooseX::Storage::IO::StorableFile> role instead.

=head1 METHODS

=over 4

=item B<freeze>

=item B<thaw ($stored)>

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

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


