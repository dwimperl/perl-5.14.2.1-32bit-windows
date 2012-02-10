=head1 NAME

PPIx::Regexp::Token::Assertion - Represent a simple assertion.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{\bfoo\b}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Assertion> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Assertion> has no descendants.

=head1 DESCRIPTION

This class represents one of the simple assertions; that is, those that
are not defined via parentheses. This includes the zero-width assertions
C<^>, C<$>, C<\b>, C<\B>, C<\A>, C<\Z>, C<\z> and C<\G>, as well as the
positive look-behind assertion C<\K> added in Perl 5.009005.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Assertion;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{ COOKIE_CLASS MINIMUM_PERL TOKEN_LITERAL };

our $VERSION = '0.025';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

{

    my %perl_version_introduced = (
	'\\K' => '5.009005',
	'\\z' => '5.005',
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	return $perl_version_introduced{$self->content()} || MINIMUM_PERL;
    }

}

# By logic we should handle '$' here. But
# PPIx::Regexp::Token::Interpolation needs to process it to see if it is
# a sigil. If it is not, that module is expected to make it into an
# assertion. This is to try to keep the order in which the tokenizers
# are called non-critical, and try to keep all processing for a
# character in one place. Except for the back slash, which gets in
# everywhere.
#
## my %assertion = map { $_ => 1 } qw{ ^ $ };
my %assertion = map { $_ => 1 } qw{ ^ };
my %escaped = map { $_ => 1 } qw{ b B A Z z G K };

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # Inside a character class, these are all literals.
    my $make = $tokenizer->cookie( COOKIE_CLASS ) ?
	TOKEN_LITERAL :
	__PACKAGE__;

    # '^' and '$'. Or at least '^'. See note above for '$'.
    $assertion{$character}
	and return $tokenizer->make_token( 1, $make );

    $character eq '\\' or return;

    defined ( my $next = $tokenizer->peek( 1 ) ) or return;

    $escaped{$next}
	and return $tokenizer->make_token( 2, $make );

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
