=head1 NAME

PPIx::Regexp::Token::GroupType::Assertion - Represent a look ahead or look behind assertion

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo(?=bar)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType::Assertion> is a
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType>.

C<PPIx::Regexp::Token::GroupType::Assertion> has no descendants.

=head1 DESCRIPTION

This class represents the parenthesized look ahead and look behind
assertions.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::GroupType::Assertion;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use PPIx::Regexp::Constant qw{ MINIMUM_PERL };

our $VERSION = '0.025';

{
    my %perl_version_introduced = (
	'?<='	=> '5.005',
	'?<!'	=> '5.005',
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	return $perl_version_introduced{ $self->content() } || MINIMUM_PERL;
    }
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # The actual expression being matched is \A \? <? [=!]. All the
    # optional escapes are because any of the non-open-bracket
    # punctuation characters may itself be escaped if it is also used to
    # quote the entire expression.
    if ( my $assert = $tokenizer->find_regexp(
	    qr{ \A \\? \? <? \\? [=!] }smx ) ) {
	return $assert;
    }

    return;
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
