
package MooseX::Storage::Meta::Attribute::DoNotSerialize;
use Moose;

our $VERSION   = '0.30';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Moose::Meta::Attribute';
   with 'MooseX::Storage::Meta::Attribute::Trait::DoNotSerialize';

# register this alias ...
package Moose::Meta::Attribute::Custom::DoNotSerialize;

our $VERSION   = '0.30';
our $AUTHORITY = 'cpan:STEVAN';

sub register_implementation { 'MooseX::Storage::Meta::Attribute::DoNotSerialize' }

1;

__END__

=pod

=head1 NAME

MooseX::Storage::Meta::Attribute::DoNotSerialize - A custom meta-attribute to bypass serialization

=head1 SYNOPSIS

  package Point;
  use Moose;
  use MooseX::Storage;
  
  with Storage('format' => 'JSON', 'io' => 'File');
  
  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');
  
  has 'foo' => (
      metaclass => 'DoNotSerialize',
      is        => 'rw',
      isa       => 'CodeRef',
  );
  
  1;

=head1 DESCRIPTION

Sometimes you don't want a particular attribute to be part of the 
serialization, in this case, you want to make sure that attribute 
uses this custom meta-attribute. See the SYNOPSIS for a nice example
that can be easily cargo-culted.

=head1 METHODS

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
