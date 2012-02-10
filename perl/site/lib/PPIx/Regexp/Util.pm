package PPIx::Regexp::Util;

use 5.006;

use strict;
use warnings;

use Carp;
use Scalar::Util qw{ blessed };

use base qw{ Exporter };

our @EXPORT_OK = qw{ __instance };

our $VERSION = '0.025';

sub __instance {
    my ( $object, $class ) = @_;
    blessed( $object ) or return;
    return $object->isa( $class );
}

1;

__END__

=head1 NAME

PPIx::Regexp::Util - Utility functions for PPIx::Regexp;

=head1 SYNOPSIS

 use PPIx::Regexp::Util qw{ __instance };
     .
     .
     .
 __instance( $foo, 'Bar' )
     or die '$foo is not a Bar';

=head1 DESCRIPTION

This module contains utility functions for L<PPIx::Regexp|PPIx::Regexp>
which it is convenient to centralize.

The contents of this module are B<private> to the
L<PPIx::Regexp|PPIx::Regexp> package. This documentation is provided for
the author's convenience only. Anything in this module is subject to
change without notice. I<Caveat user.>

This module exports nothing by default.

=head1 SUBROUTINES

This module can export the following subroutines:

=head2 __instance

 __instance( $foo, 'Bar' )
     and print '$foo isa Bar', "\n";

This subroutine returns true if its first argument is an instance of the
class specified by its second argument. Unlike C<UNIVERSAL::isa>, the
result is always false unless the first argument is a reference.


=head1 SEE ALSO

L<Params::Util|Params::Util>, which I recommend, but in the case of
C<PPIx::Regexp> I did not want to introduce a dependency on an XS module
when all I really wanted was the function of that module's
C<_INSTANCE()> subroutine.


=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
