package MooseX::Storage::IO::StorableFile;
use Moose::Role;

use Storable ();

our $VERSION   = '0.30';
our $AUTHORITY = 'cpan:STEVAN';

requires 'pack';
requires 'unpack';

sub load {
    my ( $class, $filename, @args ) = @_;
    # try thawing
    return $class->thaw( Storable::retrieve($filename), @args )
        if $class->can('thaw');
    # otherwise just unpack
    $class->unpack( Storable::retrieve($filename), @args );
}

sub store {
    my ( $self, $filename, @args ) = @_;
    Storable::nstore(
        # try freezing, otherwise just pack
        ($self->can('freeze') ? $self->freeze(@args) : $self->pack(@args)),
        $filename
    );
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

MooseX::Storage::IO::StorableFile - An Storable File I/O role

=head1 SYNOPSIS

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage('io' => 'StorableFile');

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  1;

  my $p = Point->new(x => 10, y => 10);

  ## methods to load/store a class
  ## on the file system

  $p->store('my_point');

  my $p2 = Point->load('my_point');

=head1 DESCRIPTION

This module will C<load> and C<store> Moose classes using Storable. It
uses C<Storable::nstore> by default so that it can be easily used
across machines or just locally.

One important thing to note is that this module does not mix well
with the other Format modules. Since Storable serialized perl data
structures in it's own format, those roles are lagely unnecessary.

However, there is always the possibility that having a set of
C<freeze/thaw> hooks can be useful, so because of that this module
will attempt to use C<freeze> or C<thaw> if that method is available.
Of course, you should be careful when doing this as it could lead to
all sorts of hairy issues. But you have been warned.

=head1 METHODS

=over 4

=item B<load ($filename)>

=item B<store ($filename)>

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


