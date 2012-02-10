=head1 NAME

PPIx::Regexp::Token::Operator - Represent an operator.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo|bar}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Operator> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Operator> has no descendants.

=head1 DESCRIPTION

This class represents an operator. In a character class, it represents
the negation (C<^>) and range (C<->) operators. Outside a character
class, it represents the alternation (C<|>) operator.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Operator;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{ TOKEN_LITERAL };
use PPIx::Regexp::Util qw{ __instance };

our $VERSION = '0.025';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

# These will be intercepted by PPIx::Regexp::Token::Literal if they are
# really literals, so here we may process them unconditionally.

# Note that if we receive a '-' we unconditionally make it an operator,
# relying on the lexer to turn it back into a literal if necessary.

my %operator = map { $_ => 1 } qw{ | - };

sub _treat_as_literal {
    my ( $token ) = @_;
    return __instance( $token, 'PPIx::Regexp::Token::Literal' ) ||
	__instance( $token, 'PPIx::Regexp::Token::Interpolation' );
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # We only receive the '-' if we are inside a character class. But it
    # is only an operator if it is preceded and followed by literals. We
    # can use prior() because there are no insignificant tokens inside a
    # character class.
    if ( $character eq '-' ) {

	_treat_as_literal( $tokenizer->prior() )
	    or return $tokenizer->make_token( 1, TOKEN_LITERAL );
	
	my @tokens = ( $tokenizer->make_token( 1 ) );
	push @tokens, $tokenizer->get_token();
	
	_treat_as_literal( $tokens[1] )
	    or bless $tokens[0], TOKEN_LITERAL;
	
	return ( @tokens );
    }

    return $operator{$character};
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
