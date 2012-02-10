=head1 NAME

PPIx::Regexp::Token::Code - Represent a chunk of Perl embedded in a regular expression.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new(
     'qr{(?{print "hello sailor\n"})}smx')->print;

=head1 INHERITANCE

C<PPIx::Regexp::Token::Code> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Code> is the parent of
L<PPIx::Regexp::Token::Interpolation|PPIx::Regexp::Token::Interpolation>.

=head1 DESCRIPTION

This class represents a chunk of Perl code embedded in a regular
expression. Specifically, it results from parsing things like

 (?{ code })
 (??{ code })

or from the replacement side of an s///e. Technically, interpolations
are also code, but they parse differently and therefore end up in a
different token.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Token::Code;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPI::Document;
use PPIx::Regexp::Util qw{ __instance };

our $VERSION = '0.025';

sub _new {
    my ( $class, $content ) = @_;
    ref $class and $class = ref $class;

    my $self = {};
    if ( __instance( $content, 'PPI::Document' ) ) {
	$self->{ppi} = $content;
    } elsif ( ref $content ) {
	return;
    } else {
	$self->{content} = $content;
    }
    bless $self, $class;
    return $self;
}

sub content {
    my ( $self ) = @_;
    if ( exists $self->{content} ) {
	return $self->{content};
    } elsif ( exists $self->{ppi} ) {
	return ( $self->{content} = $self->{ppi}->content() );
    } else {
	return;
    }
}

sub perl_version_introduced {
    my ( $self ) = @_;
    return $self->{perl_version_introduced};
}

=head2 ppi

This convenience method returns the L<PPI::Document|PPI::Document>
representing the content. This document should be considered read only.

=cut

sub ppi {
    my ( $self ) = @_;
    if ( exists $self->{ppi} ) {
	return $self->{ppi};
    } elsif ( exists $self->{content} ) {
	return ( $self->{ppi} = PPI::Document->new(
		\($self->{content}), readonly => 1 ) );
    } else {
	return;
    }
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

{

    my %default = (
	perl_version_introduced	=> '5.005',	# When (?{...}) introduced.
    );

    sub __PPIX_TOKEN__post_make {
	my ( $self, $tokenizer, $arg ) = @_;

	if ( 'HASH' eq ref $arg ) {
	    foreach my $key ( qw{ perl_version_introduced } ) {
		exists $arg->{$key}
		    and $self->{$key} = $arg->{$key};
	    }
	}

	foreach my $key ( keys %default ) {
	    exists $self->{$key}
		or $self->{$key} = $default{$key};
	}

	return;
    }

}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    $character eq '{' or return;

    my $offset = $tokenizer->find_matching_delimiter()
	or return;

    return $offset + 1;	# to include the closing delimiter.
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
