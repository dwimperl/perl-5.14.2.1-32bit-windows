
package Moose::Autobox;
use 5.006;
use strict;
use warnings;

use Carp        qw(confess);
use Scalar::Util ();
use Moose::Util  ();

our $VERSION = '0.11';

use base 'autobox';

use Moose::Autobox::Undef;

sub import {
    (shift)->SUPER::import(
        DEFAULT => 'Moose::Autobox::',
        UNDEF   => 'Moose::Autobox::Undef',
    );
}

sub mixin_additional_role {
    my ($class, $type, $role) = @_;
    ($type =~ /SCALAR|ARRAY|HASH|CODE/)
        || confess "Can only add additional roles to SCALAR, ARRAY, HASH or CODE";
    Moose::Util::apply_all_roles(('Moose::Autobox::' . $type)->meta, ($role));
}

{
                        
    package Moose::Autobox::SCALAR;

    use Moose::Autobox::Scalar;

    use metaclass 'Moose::Meta::Class';

    Moose::Util::apply_all_roles(__PACKAGE__->meta, ('Moose::Autobox::Scalar'));

    *does = \&Moose::Object::does;

    package Moose::Autobox::ARRAY;

    use Moose::Autobox::Array;

    use metaclass 'Moose::Meta::Class';

    Moose::Util::apply_all_roles(__PACKAGE__->meta, ('Moose::Autobox::Array'));

    *does = \&Moose::Object::does;

    package Moose::Autobox::HASH;

    use Moose::Autobox::Hash;

    use metaclass 'Moose::Meta::Class';

    Moose::Util::apply_all_roles(__PACKAGE__->meta, ('Moose::Autobox::Hash'));

    *does = \&Moose::Object::does;

    package Moose::Autobox::CODE;

    use Moose::Autobox::Code;

    use metaclass 'Moose::Meta::Class';

    Moose::Util::apply_all_roles(__PACKAGE__->meta, ('Moose::Autobox::Code'));

    *does = \&Moose::Object::does;            
 
} 
                 
1;

__END__

=pod

=head1 NAME 

Moose::Autobox - Autoboxed wrappers for Native Perl datatypes 

=head1 SYNOPOSIS

  use Moose::Autobox;
  
  print 'Print squares from 1 to 10 : ';
  print [ 1 .. 10 ]->map(sub { $_ * $_ })->join(', ');

=head1 DESCRIPTION

Moose::Autobox provides an implementation of SCALAR, ARRAY, HASH
& CODE for use with L<autobox>. It does this using a hierarchy of 
roles in a manner similar to what Perl 6 I<might> do. This module, 
like L<Class::MOP> and L<Moose>, was inspired by my work on the 
Perl 6 Object Space, and the 'core types' implemented there.

=head2 A quick word about autobox

The L<autobox> module provides the ability for calling 'methods' 
on normal Perl values like Scalars, Arrays, Hashes and Code 
references. This gives the illusion that Perl's types are first-class 
objects. However, this is only an illusion, albeit a very nice one.
I created this module because L<autobox> itself does not actually 
provide an implementation for the Perl types but instead only provides 
the 'hooks' for others to add implementation too.

=head2 Is this for real? or just play?

Several people are using this module in serious applications and 
it seems to be quite stable. The underlying technologies of L<autobox>
and L<Moose::Role> are also considered stable. There is some performance
hit, but as I am fond of saying, nothing in life is free. If you have 
any questions regarding this module, either email me, or stop by #moose
on irc.perl.org and ask around.

=head2 Adding additional methods

B<Moose::Autobox> asks L<autobox> to use the B<Moose::Autobox::*> namespace 
prefix so as to avoid stepping on the toes of other L<autobox> modules. This 
means that if you want to add methods to a particular perl type 
(i.e. - monkeypatch), then you must do this:

  sub Moose::Autobox::SCALAR::bar { 42 }

instead of this:

  sub SCALAR::bar { 42 }

as you would with vanilla autobox.

=head1 METHODS

=over 4

=item B<mixin_additional_role ($type, $role)>

This will mixin an additonal C<$role> into a certain C<$type>. The 
types can be SCALAR, ARRAY, HASH or CODE.

This can be used to add additional methods to the types, see the 
F<examples/units/> directory for some examples.

=back

=head1 TODO

=over 4

=item More docs

=item More tests

=back
  
=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

B<with contributions from:>

Anders (Debolaz) Nor Berle

Matt (mst) Trout

renormalist

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
