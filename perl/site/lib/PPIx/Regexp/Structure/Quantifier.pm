=head1 NAME

PPIx::Regexp::Structure::Quantifier - Represent curly bracket quantifiers

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{fo{2,}}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Quantifier> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::Quantifier> has no descendants.

=head1 DESCRIPTION

This class represents curly bracket quantifiers such as C<{3}>, C<{3,}>
and C<{3,5}>. The contents are left as literals or interpolations.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Structure::Quantifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

our $VERSION = '0.025';

sub can_be_quantified {
    return;
}

sub is_quantifier {
    return 1;
}

# Called by the lexer to record the capture number.
sub __PPIX_LEXER__record_capture_number {
    my ( $self, $number ) = @_;
    return $number;
}

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
