=head1 NAME

PPIx::Regexp::Node::Range - Represent a character range in a character class

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{[a-z]}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Node::Range> is a
L<PPIx::Regexp::Node|PPIx::Regexp::Node>.

C<PPIx::Regexp::Node::Range> has no descendants.

=head1 DESCRIPTION

This class represents a character range in a character class. It is a
node rather than a structure because there are no delimiters. The
content is simply the two literals with the '-' operator between them.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Node::Range;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Node };

our $VERSION = '0.025';

1;

__END__

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2012 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
