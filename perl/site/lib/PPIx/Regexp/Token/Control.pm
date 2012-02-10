=head1 NAME

PPIx::Regexp::Token::Control - Case and quote control.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{\Ufoo\E}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Control> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Control> has no descendants.

=head1 DESCRIPTION

This class represents the case and quote controls. These apply when the
regular expression is compiled, changing the actual expression
generated. For example

 print qr{\Ufoo\E}, "\n"

prints

 (?-xism:FOO)

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Control;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{ COOKIE_QUOTE TOKEN_LITERAL TOKEN_UNKNOWN };

our $VERSION = '0.025';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

my %is_control = map { $_ => 1 } qw{ l u L U Q E };
my %cookie = (
    Q	=> sub { return 1; },
    E	=> undef,
);

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # If we are inside a quote sequence, we want to make literals out of
    # all the characters we reject; otherwise we just want to return
    # nothing.
    my $in_quote = $tokenizer->cookie( COOKIE_QUOTE );
    my $reject = $in_quote ?
	sub {
	    my ( $size, $class ) = @_;
	    return $tokenizer->make_token( $size, $class || TOKEN_LITERAL );
	} : sub {
	    return;
	};

    # We are not interested in anything that is not escaped.
    $character eq '\\' or return $reject->( 1 );

    # We need to see what the next character is to figure out what to
    # do. If there is no next character, we do not know what to call the
    # back slash.
    my $control = $tokenizer->peek( 1 )
	or return $reject->( 1, TOKEN_UNKNOWN );

    # We reject any escapes that do not represent controls.
    $is_control{$control} or return $reject->( 2 );

    # If we are quoting, we reject anything but an end quote.
    $in_quote and $control ne 'E' and return $reject->( 2 );

    # Anything left gets made into a token now, to avoid its processing
    # by the cookie we may make.
    my $token = $tokenizer->make_token( 2 );

    # \Q and \E make and destroy cookies respectively; do those things.
    exists $cookie{$control}
	and $tokenizer->cookie( COOKIE_QUOTE, $cookie{$control} );

    # Return our token.
    return $token;
}

sub __PPIX_TOKENIZER__repl {
    my ( $class, $tokenizer, $character ) = @_;

    $tokenizer->interpolates() and goto &__PPIX_TOKENIZER__regexp;

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
