package MooseX::Types::Path::Class;

use warnings FATAL => 'all';
use strict;

our $VERSION = '0.05';
our $AUTHORITY = 'cpan:THEPLER';

use Path::Class ();
# TODO: export dir() and file() from Path::Class? (maybe)

use MooseX::Types
    -declare => [qw( Dir File )];

use MooseX::Types::Moose qw(Str ArrayRef);

class_type('Path::Class::Dir');
class_type('Path::Class::File');

subtype Dir, as 'Path::Class::Dir';
subtype File, as 'Path::Class::File';

for my $type ( 'Path::Class::Dir', Dir ) {
    coerce $type,
        from Str,      via { Path::Class::Dir->new($_) },
        from ArrayRef, via { Path::Class::Dir->new(@$_) };
}

for my $type ( 'Path::Class::File', File ) {
    coerce $type,
        from Str,      via { Path::Class::File->new($_) },
        from ArrayRef, via { Path::Class::File->new(@$_) };
}

# optionally add Getopt option type
eval { require MooseX::Getopt; };
if ( !$@ ) {
    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( $_, '=s', )
        for ( 'Path::Class::Dir', 'Path::Class::File', Dir, File, );
}

1;
__END__


=head1 NAME

MooseX::Types::Path::Class - A Path::Class type library for Moose


=head1 SYNOPSIS

  package MyClass;
  use Moose;
  use MooseX::Types::Path::Class;
  with 'MooseX::Getopt';  # optional

  has 'dir' => (
      is       => 'ro',
      isa      => 'Path::Class::Dir',
      required => 1,
      coerce   => 1,
  );

  has 'file' => (
      is       => 'ro',
      isa      => 'Path::Class::File',
      required => 1,
      coerce   => 1,
  );

  # these attributes are coerced to the
  # appropriate Path::Class objects
  MyClass->new( dir => '/some/directory/', file => '/some/file' );

  
=head1 DESCRIPTION

MooseX::Types::Path::Class creates common L<Moose> types,
coercions and option specifications useful for dealing
with L<Path::Class> objects as L<Moose> attributes.

Coercions (see L<Moose::Util::TypeConstraints>) are made
from both 'Str' and 'ArrayRef' to both L<Path::Class::Dir> and
L<Path::Class::File> objects.  If you have L<MooseX::Getopt> installed,
the Getopt option type ("=s") will be added for both
L<Path::Class::Dir> and L<Path::Class::File>.


=head1 EXPORTS

None of these are exported by default.  They are provided via
L<MooseX::Types>.

=over

=item Dir, File

These exports can be used instead of the full class names.  Example:

  package MyClass;
  use Moose;
  use MooseX::Types::Path::Class qw(Dir File);

  has 'dir' => (
      is       => 'ro',
      isa      => Dir,
      required => 1,
      coerce   => 1,
  );

  has 'file' => (
      is       => 'ro',
      isa      => File,
      required => 1,
      coerce   => 1,
  );

Note that there are no quotes around Dir or File.

=item is_Dir($value), is_File($value)

Returns true or false based on whether $value is a valid Dir or File.

=item to_Dir($value), to_File($value)

Attempts to coerce $value to a Dir or File.  Returns the coerced value
or false if the coercion failed.

=back


=head1 DEPENDENCIES

L<Moose>, L<MooseX::Types>, L<Path::Class>


=head1 BUGS AND LIMITATIONS

If you find a bug please either email the author, or add
the bug to cpan-RT L<http://rt.cpan.org>.


=head1 AUTHOR

Todd Hepler  C<< <thepler@employees.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2008, Todd Hepler C<< <thepler@employees.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


