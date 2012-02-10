=head1 NAME

PPIx::Regexp::Token::GroupType::NamedCapture - Represent a named capture

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?<baz>foo)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType::NamedCapture> is a
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType>.

C<PPIx::Regexp::Token::GroupType::NamedCapture> has no descendants.

=head1 DESCRIPTION

This class represents a named capture specification. Its content will be
something like one of the following:

 ?<NAME>
 ?'NAME'
 ?P<NAME>

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Token::GroupType::NamedCapture;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use Carp qw{ confess };

use PPIx::Regexp::Constant qw{ RE_CAPTURE_NAME };

our $VERSION = '0.025';

use constant NAMED_CAPTURE =>
    qr{ \A \\? \? (?: P? < ( @{[ RE_CAPTURE_NAME ]} ) \\? > |
		\\? ' ( @{[ RE_CAPTURE_NAME ]} ) \\? ' ) }smxo;

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

=head2 name

This method returns the name of the capture.

=cut

sub name {
    my ( $self ) = @_;
    return $self->{name};
}

sub perl_version_introduced {
    return '5.009005';
}

sub __PPIX_TOKEN__post_make {
    my ( $self, $tokenizer ) = @_;
    if ( $tokenizer ) {
	foreach my $name ( $tokenizer->capture() ) {
	    defined $name or next;
	    $self->{name} = $name;
	    return;
	}
    } else {
	foreach my $name (
	    $self->content() =~ m/ @{[ NAMED_CAPTURE ]} /smxo ) {
	    defined $name or next;
	    $self->{name} = $name;
	    return;
	}
    }

    confess 'Programming error - can not figure out capture name';
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # The optional escapes are because any of the non-open-bracket
    # punctuation characters may be the expression delimiter.
    if ( my $accept = $tokenizer->find_regexp( NAMED_CAPTURE ) ) {
	return $accept;
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
