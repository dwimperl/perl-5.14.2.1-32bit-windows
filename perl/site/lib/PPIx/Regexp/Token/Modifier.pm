=head1 NAME

PPIx::Regexp::Token::Modifier - Represent modifiers.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo}smx' )
     ->print();

The trailing C<smx> will be represented by this class.

This class also represents the whole of things like C<(?ismx)>. But the
modifiers in something like C<(?i:foo)> are represented by a
L<PPIx::Regexp::Token::GroupType::Modifier|PPIx::Regexp::Token::GroupType::Modifier>.

=head1 INHERITANCE

C<PPIx::Regexp::Token::Modifier> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Modifier> is the parent of
L<PPIx::Regexp::Token::GroupType::Modifier|PPIx::Regexp::Token::GroupType::Modifier>.

=head1 DESCRIPTION

This class represents modifier characters at the end of the regular
expression.  For example, in C<qr{foo}smx> this class would represent
the terminal C<smx>.

=head2 The C<a>, C<aa>, C<d>, C<l>, and C<u> modifiers

The C<a>, C<aa>, C<d>, C<l>, and C<u> modifiers, introduced starting in
Perl 5.13.6, are used to force either Unicode pattern semantics (C<u>),
locale semantics (C<l>) default semantics (C<d> the traditional Perl
semantics, which can also mean 'dual' since it means Unicode if the
string's UTF-8 bit is on, and locale if the UTF-8 bit is off), or
restricted default semantics (C<a>). These are mutually exclusive, and
only one can be asserted at a time. Asserting any of these overrides
the inherited value of any of the others. The C<asserted()> method
reports as asserted the last one it sees, or none of them if it has seen
none.

For example, given C<PPIx::Regexp::Token::Modifier> C<$elem>
representing the invalid regular expression fragment C<(?dul)>,
C<< $elem->asserted( 'l' ) >> would return true, but
C<< $elem->asserted( 'u' ) >> would return false. Note that
C<< $elem->negated( 'u' ) >> would also return false, since C<u> is not
explicitly negated.

If C<$elem> represented regular expression fragment C<(?i)>,
C<< $elem->asserted( 'd' ) >> would return false, since even though C<d>
represents the default behavior it is not explicitly asserted.

=head2 The caret (C<^>) modifier

Calling C<^> a modifier is a bit of a misnomer. The C<(?^...)>
construction was introduced in Perl 5.13.6, to prevent the inheritance
of modifiers. The documentation calls the caret a shorthand equivalent
for C<d-imsx>, and that it the way this class handles it.

For example, given C<PPIx::Regexp::Token::Modifier> C<$elem>
representing regular expression fragment C<(?^i)>,
C<< $elem->asserted( 'd' ) >> would return true, since in the absence of
an explicit C<l> or C<u> this class considers the C<^> to explicitly
assert C<d>.

B<Note> that if this is retracted before Perl 5.14 is released, this
support will disappear. See L<PPIx::Regexp/NOTICE> for some explanation.

=head1 METHODS

This class provides the following public methods. Methods not documented
here are private, and unsupported in the sense that the author reserves
the right to change or remove them without notice.

=cut

package PPIx::Regexp::Token::Modifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{
    MINIMUM_PERL
    MODIFIER_GROUP_MATCH_SEMANTICS
};

our $VERSION = '0.025';

# Define modifiers that are to be aggregated internally for ease of
# computation.
my %aggregate = (
    a	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    aa	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    d	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    l	=> MODIFIER_GROUP_MATCH_SEMANTICS,
    u	=> MODIFIER_GROUP_MATCH_SEMANTICS,
);
my %de_aggregate;
foreach my $value ( values %aggregate ) {
    $de_aggregate{$value}++;
}

=head2 asserts

 $token->asserts( 'i' ) and print "token asserts i";
 foreach ( $token->asserts() ) { print "token asserts $_\n" }

This method returns true if the token explicitly asserts the given
modifier. The example would return true for the modifier in
C<(?i:foo)>, but false for C<(?-i:foo)>.

If called without an argument, or with an undef argument, all modifiers
explicitly asserted by this token are returned.

=cut

sub asserts {
    my ( $self, $modifier ) = @_;
    $self->{modifiers} ||= $self->_decode();
    if ( defined $modifier ) {
	return __asserts( $self->{modifiers}, $modifier );
    } else {
	return ( sort grep { defined $_ && $self->{modifiers}{$_} }
	    map { $de_aggregate{$_} ? $self->{modifiers}{$_} : $_ }
	    keys %{ $self->{modifiers} } );
    }
}

sub __asserts {
    my ( $present, $modifier ) = @_;
    my $bin = $aggregate{$modifier}
	or return $present->{$modifier};
    return defined $present->{$bin} && $modifier eq $present->{$bin};
}

sub can_be_quantified { return };

=head2 match_semantics

 my $sem = $token->match_semantics();
 defined $sem or $sem = 'undefined';
 print "This token has $sem match semantics\n";

This method returns the match semantics asserted by the token, as one of
the strings C<'a'>, C<'aa'>, C<'d'>, C<'l'>, or C<'u'>. If no explicit
match semantics are asserted, this method returns C<undef>.

=cut

sub match_semantics {
    my ( $self ) = @_;
    $self->{modifiers} ||= $self->_decode();
    return $self->{modifiers}{ MODIFIER_GROUP_MATCH_SEMANTICS() };
}

=head2 modifiers

 my %mods = $token->modifiers();

Returns all modifiers asserted or negated by this token, and the values
set (true for asserted, false for negated). If called in scalar context,
returns a reference to a hash containing the values.

=cut

sub modifiers {
    my ( $self ) = @_;
    $self->{modifiers} ||= $self->_decode();
    my %mods = %{ $self->{modifiers} };
    foreach my $bin ( keys %de_aggregate ) {
	defined ( my $val = delete $mods{$bin} )
	    or next;
	$mods{$bin} = $val;
    }
    return wantarray ? %mods : \%mods;
}

=head2 negates

 $token->negates( 'i' ) and print "token negates i\n";
 foreach ( $token->negates() ) { print "token negates $_\n" }

This method returns true if the token explicitly negates the given
modifier. The example would return true for the modifier in
C<(?-i:foo)>, but false for C<(?i:foo)>.

If called without an argument, or with an undef argument, all modifiers
explicitly negated by this token are returned.

=cut

sub negates {
    my ( $self, $modifier ) = @_;
    $self->{modifiers} ||= $self->_decode();
    # Note that since the values of hash entries that represent
    # aggregated modifiers will never be false (at least, not unless '0'
    # becomes a modifier) we need no special logic to handle them.
    defined $modifier
	or return ( sort grep { ! $self->{modifiers}{$_} }
	    keys %{ $self->{modifiers} } );
    return exists $self->{modifiers}{$modifier}
	&& ! $self->{modifiers}{$modifier};
}

sub perl_version_introduced {
    my ( $self ) = @_;
    return ( $self->{perl_version_introduced} ||=
	$self->_perl_version_introduced() );
}

sub _perl_version_introduced {
    my ( $self ) = @_;
    my $content = $self->content();
    my $is_statement_modifier = ( $content !~ m/ \A [(]? [?] /smx );
    my $match_semantics = $self->match_semantics();

    # Match semantics modifiers became available as regular expression
    # modifiers in 5.13.10.
    defined $match_semantics
	and $is_statement_modifier
	and return '5.013010';

    # /aa was introduced in 5.13.10.
    defined $match_semantics
	and 'aa' eq $match_semantics
	and return '5.013010';

    # /a was introduced in 5.13.9, but only in (?...), not as modifier
    # of the entire regular expression.
    defined $match_semantics
	and not $is_statement_modifier
	and 'a' eq $match_semantics
	and return '5.013009';

    # /d, /l, and /u were introduced in 5.13.6, but only in (?...), not
    # as modifiers of the entire regular expression.
    defined $match_semantics
	and not $is_statement_modifier
	and return '5.013006';

    # The '^' reassert-defaults modifier in embedded modifiers was
    # introduced in 5.13.6.
    not $is_statement_modifier
	and $content =~ m/ \^ /smx
	and return '5.013006';

    $self->asserts( 'r' ) and return '5.013002';
    $self->asserts( 'p' ) and return '5.009005';
    $self->content() =~ m/ \A [(]? [?] .* - /smx
			and return '5.005';
    $self->asserts( 'c' ) and return '5.004';
    return MINIMUM_PERL;
}

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };


# $present => __aggregate_modifiers( 'modifiers', ... );
#
# This subroutine is private to the PPIx::Regexp package. It may change
# or be retracted without notice. Its purpose is to support defaulted
# modifiers.
#
# Aggregate the given modifiers left-to-right, returning a hash of those
# present and their values.

sub __aggregate_modifiers {
    my ( @mods ) = @_;
    my %present;
    foreach my $content ( @mods ) {
	$content =~ s{ [?/]+ }{}smxg;
	if ( $content =~ m/ \A \^ /smx ) {
	    @present{ MODIFIER_GROUP_MATCH_SEMANTICS(), qw{ i s m x } }
		= qw{ d 0 0 0 0 };
	}

	# Have to do the global match rather than a split, because the
	# expression modifiers come through here too, and we need to
	# distinguish between s/.../.../e and s/.../.../ee.
	my $value = 1;
	while ( $content =~ m/ ( ( [[:alpha:]-] ) \2* ) /smxg ) {
	    if ( '-' eq $1 ) {
		$value = 0;
	    } elsif ( my $bin = $aggregate{$1} ) {
		$present{$bin} = $value ? $1 : undef;
	    } else {
		$present{$1} = $value;
	    }
	}
    }
    return \%present;
}

# This must be implemented by tokens which do not recognize themselves.
# The return is a list of list references. Each list reference must
# contain a regular expression that recognizes the token, and optionally
# a reference to a hash to pass to make_token as the class-specific
# arguments. The regular expression MUST be anchored to the beginning of
# the string.
sub __PPIX_TOKEN__recognize {
    return (
	[ qr{ \A [(] [?] [[:lower:]]* -? [[:lower:]]* [)] }smx ],
	[ qr{ \A [(] [?] \^ [[:lower:]]* [)] }smx ],
    );
}

# After the token is made, figure out what it asserts or negates.

sub __PPIX_TOKEN__post_make {
    my ( $self, $tokenizer ) = @_;
    defined $tokenizer
	and $tokenizer->modifier_modify( $self->modifiers() );
    return;
}

{

    # Called by the tokenizer to modify the current modifiers with a new
    # set. Both are passed as hash references, and a reference to the
    # new hash is returned.
    sub __PPIX_TOKENIZER__modifier_modify {
	my ( @args ) = @_;

	my %merged;
	foreach my $hash ( @args ) {
	    while ( my ( $key, $val ) = each %{ $hash } ) {
		if ( $val ) {
		    $merged{$key} = $val;
		} else {
		    delete $merged{$key};
		}
	    }
	}

	return \%merged;

    }

    # Decode modifiers from the content of the token.
    sub _decode {
	my ( $self ) = @_;
	return __aggregate_modifiers( $self->content() );
    }
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
