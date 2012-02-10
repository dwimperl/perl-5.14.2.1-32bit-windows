package PPIx::Regexp::Tokenizer;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Support };

use Carp qw{ confess };
use PPIx::Regexp::Constant qw{
    MINIMUM_PERL
    TOKEN_LITERAL
    TOKEN_UNKNOWN
};
use PPIx::Regexp::Token::Assertion		();
use PPIx::Regexp::Token::Backreference		();
use PPIx::Regexp::Token::Backtrack		();
use PPIx::Regexp::Token::CharClass::POSIX	();
use PPIx::Regexp::Token::CharClass::POSIX::Unknown	();
use PPIx::Regexp::Token::CharClass::Simple	();
use PPIx::Regexp::Token::Code			();
use PPIx::Regexp::Token::Comment		();
use PPIx::Regexp::Token::Condition		();
use PPIx::Regexp::Token::Control		();
use PPIx::Regexp::Token::Delimiter		();
use PPIx::Regexp::Token::Greediness		();
use PPIx::Regexp::Token::GroupType::Assertion	();
use PPIx::Regexp::Token::GroupType::BranchReset	();
use PPIx::Regexp::Token::GroupType::Code	();
use PPIx::Regexp::Token::GroupType::Modifier	();
use PPIx::Regexp::Token::GroupType::NamedCapture	();
use PPIx::Regexp::Token::GroupType::Subexpression	();
use PPIx::Regexp::Token::GroupType::Switch	();
use PPIx::Regexp::Token::Interpolation		();
use PPIx::Regexp::Token::Literal		();
use PPIx::Regexp::Token::Modifier		();
use PPIx::Regexp::Token::Operator		();
use PPIx::Regexp::Token::Quantifier		();
use PPIx::Regexp::Token::Recursion		();
use PPIx::Regexp::Token::Structure		();
use PPIx::Regexp::Token::Unknown		();
use PPIx::Regexp::Token::Whitespace		();
use PPIx::Regexp::Util qw{ __instance };
use Scalar::Util qw{ looks_like_number };

our $VERSION = '0.025';

{
    # Names of classes containing tokenization machinery. There are few
    # known ordering requirements, since each class recognizes its own,
    # and I have tried to prevent overlap. Absent such constraints, the
    # order is in percieved frequency of acceptance, to keep the search
    # as short as possible. If I were conscientious I would gather
    # statistics on this.
    my @classes = (	# TODO make readonly when acceptable way appears
	'PPIx::Regexp::Token::Literal',
	'PPIx::Regexp::Token::Interpolation',
	'PPIx::Regexp::Token::Control',			# Note 1
	'PPIx::Regexp::Token::CharClass::Simple',	# Note 2
        'PPIx::Regexp::Token::Quantifier',
	'PPIx::Regexp::Token::Greediness',
	'PPIx::Regexp::Token::CharClass::POSIX',	# Note 3
	'PPIx::Regexp::Token::Structure',
	'PPIx::Regexp::Token::Assertion',
	'PPIx::Regexp::Token::Backreference',
	'PPIx::Regexp::Token::Operator',		# Note 4
    );

    # Note 1: If we are in quote mode ( \Q ... \E ), Control makes a
    #		literal out of anything it sees other than \E. So it
    #		needs to come before almost all other tokenizers. Not
    #		Literal, which already makes literals, and not
    #		Interpolation, which is legal in quote mode, but
    #		everything else.

    # Note 2: CharClass::Simple must come after Literal, because it
    #		relies on Literal to recognize a Unicode named character
    #		( \N{something} ), so any \N that comes through to it
    #		must be the \N simple character class (which represents
    #		anything but a newline, and was introduced in Perl
    #		5.11.0.

    # Note 3: CharClass::POSIX has to come before Structure, since both
    #		look for square brackets, and CharClass::POSIX is the
    #		more particular.

    # Note 4: Operator relies on Literal making the characters literal
    #		if they appear in a context where they can not be
    #		operators, and Control making them literals if quoting,
    #		so it must come after both.

    sub _known_tokenizers {
	my ( $self ) = @_;

	my $mode = $self->{mode};

	my @expect;
	if ( $self->{expect_next} ) {
	    $self->{expect} = $self->{expect_next};
	    $self->{expect_next} = undef;
	}
	if ( $self->{expect} ) {
	    @expect = $self->_known_tokenizer_check(
		@{ $self->{expect} } );
	}

	exists $self->{known}{$mode} and return (
	    @expect, @{ $self->{known}{$mode} } );

	my @found = $self->_known_tokenizer_check( @classes );

	$self->{known}{$mode} = \@found;
	return (@expect, @found);
    }

    sub _known_tokenizer_check {
	my ( $self, @args ) = @_;

	my $mode = $self->{mode};

	my $handler = '__PPIX_TOKENIZER__' . $mode;
	my @found;

	foreach my $class ( @args ) {

	    $class->can( $handler ) or next;
	    push @found, $class;

	}

	return @found;
    }

}

{
    my $errstr;

    sub new {
	my ( $class, $re, %args ) = @_;
	ref $class and $class = ref $class;

	$errstr = undef;

	exists $args{default_modifiers}
	    and 'ARRAY' ne ref $args{default_modifiers}
	    and do {
		$errstr = 'default_modifiers must be an array reference';
		return;
	    };

	my $self = {
	    capture => undef,	# Captures from find_regexp.
	    content => undef,	# The string we are tokenizing.
	    cookie => {},	# Cookies
	    cursor_curr => 0,	# The current position in the string.
	    cursor_limit => undef, # The end of the portion of the
	    			   # string being tokenized.
	    cursor_orig => undef, # Position of cursor when tokenizer
	    			# called. Used by get_token to prevent
				# recursion.
	    cursor_modifiers => undef,	# Position of modifiers.
	    default_modifiers => $args{default_modifiers} || [],
	    delimiter_finish => undef,	# Finishing delimiter of regexp.
	    delimiter_re =>	undef,	# Recognize finishing delimiter.
	    delimiter_start => undef,	# Starting delimiter of regexp.
	    encoding => $args{encoding}, # Character encoding.
	    expect => undef,	# Extra classes to expect.
	    expect_next => undef, # Extra classes as of next parse cycle
	    failures => 0,	# Number of parse failures.
	    find => undef,	# String for find_regexp
	    known => {},	# Known tokenizers, by mode.
	    match => undef,	# Match from find_regexp.
	    mode => 'init',	# Initialize
	    modifiers => [{}],	# Modifier hash.
	    pending => [],	# Tokens made but not returned.
	    prior => TOKEN_UNKNOWN,	# Prior significant token.
	    source => $re,	# The object we were initialized with.
	    trace => __PACKAGE__->_defined_or(
		$args{trace}, $ENV{PPIX_REGEXP_TOKENIZER_TRACE}, 0 ),
	};

	if ( __instance( $re, 'PPI::Element' ) ) {
	    $self->{content} = $re->content();
	} elsif ( ref $re ) {
	    $errstr = ref( $re ) . ' not supported';
	    return;
	} else {
	    $self->{content} = $re;
	}

	bless $self, $class;

	$self->{content} = $self->decode( $self->{content} );

	if ( $self->{content} =~ m/ \s+ \z /smx ) {
	    $self->{cursor_limit} = $-[0];
	} else {
	    $self->{cursor_limit} = length $self->{content};
	}

	$self->{trace}
	    and warn "\ntokenizing '$self->{content}'\n";

	return $self;
    }

    sub errstr {
	return $errstr;
    }

}

sub capture {
    my ( $self ) = @_;
    $self->{capture} or return;
    defined wantarray or return;
    return wantarray ? @{ $self->{capture} } : $self->{capture};
}

sub content {
    my ( $self ) = @_;
    return $self->{content};
}

sub cookie {
    my ( $self, $name, @args ) = @_;
    defined $name
	or confess "Programming error - undefined cookie name";
    @args or return $self->{cookie}{$name};
    my $cookie = shift @args;
    if ( ref $cookie eq 'CODE' ) {
	return ( $self->{cookie}{$name} = $cookie );
    } elsif ( defined $cookie ) {
	confess "Programming error - cookie must be CODE ref or undef";
    } else {
	return delete $self->{cookie}{$name};
    }
}

sub default_modifiers {
    my ( $self ) = @_;
    return [ @{ $self->{default_modifiers} } ];
}

sub __effective_modifiers {
    my ( $self ) = @_;
    'HASH' eq ref $self->{effective_modifiers}
	or return {};
    return { %{ $self->{effective_modifiers} } };
}

sub encoding {
    my ( $self ) = @_;
    return $self->{encoding};
}

sub expect {
    my ( $self, @args ) = @_;
    $self->{expect_next} = [
	map { m/ \A PPIx::Regexp:: /smx ? $_ : 'PPIx::Regexp::' . $_ }
	@args
    ];
    $self->{expect} = undef;
    return;
}

sub failures {
    my ( $self ) = @_;
    return $self->{failures};
}

sub find_matching_delimiter {
    my ( $self ) = @_;
    $self->{cursor_curr} ||= 0;
    my $start = substr
	$self->{content},
	$self->{cursor_curr},
	1;

    my $inx = $self->{cursor_curr};
    my $finish = (
	my $bracketed = $self->close_bracket( $start ) ) || $start;
    my $nest = 0;

    while ( ++$inx < $self->{cursor_limit} ) {
	my $char = substr $self->{content}, $inx, 1;
	if ( $char eq '\\' && $finish ne '\\' ) {
	    ++$inx;
	} elsif ( $bracketed && $char eq $start ) {
	    ++$nest;
	} elsif ( $char eq $finish ) {
	    --$nest < 0
		and return $inx - $self->{cursor_curr};
	}
    }

    return;
}

sub find_regexp {
    my ( $self, $regexp ) = @_;

    ref $regexp eq 'Regexp'
	or confess
	'Argument is a ', ( ref $regexp || 'scalar' ), ' not a Regexp';

    defined $self->{find} or $self->_remainder();

    $self->{find} =~ $regexp
	or return;

    my @capture;
    foreach my $inx ( 0 .. $#+ ) {
	if ( defined $-[$inx] && defined $+[$inx] ) {
	push @capture, $self->{capture} = substr
		    $self->{find},
		    $-[$inx],
		    $+[$inx] - $-[$inx];
	} else {
	    push @capture, undef;
	}
    }
    $self->{match} = shift @capture;
    $self->{capture} = \@capture;

    # The following circumlocution seems to be needed under Perl 5.13.0
    # for reasons I do not fathom -- at least in the case where
    # wantarray is false. RT 56864 details the symptoms, which I was
    # never able to reproduce outside Perl::Critic. But returning $+[0]
    # directly, the value could transmogrify between here and the
    # calling module.
##  my @data = ( $-[0], $+[0] );
##  return wantarray ? @data : $data[1];
    return wantarray ? ( $-[0] + 0, $+[0] + 0 ) : $+[0] + 0;
}

sub get_token {
    my ( $self ) = @_;

    caller eq __PACKAGE__ or $self->{cursor_curr} > $self->{cursor_orig}
	or confess 'Programming error - get_token() called without ',
	    'first calling make_token()';

    my $handler = '__PPIX_TOKENIZER__' . $self->{mode};

    my $character = substr(
	$self->{content},
	$self->{cursor_curr},
	1
    );

    return ( __PACKAGE__->$handler( $self, $character ) );
}

sub interpolates {
    my ( $self ) = @_;
    return $self->{delimiter_start} ne q{'};
}

sub make_token {
    my ( $self, $length, $class, $arg ) = @_;
    defined $class or $class = caller;

    if ( $length + $self->{cursor_curr} > $self->{cursor_limit} ) {
	$length = $self->{cursor_limit} - $self->{cursor_curr}
	    or return;
    }

    $class =~ m/ \A PPIx::Regexp:: /smx
	or $class = 'PPIx::Regexp::' . $class;
    my $content = substr
	    $self->{content},
	    $self->{cursor_curr},
	    $length;

    $self->{trace}
	and warn "make_token( $length, '$class' ) => '$content'\n";
    $self->{trace} > 1
	and warn "    make_token: cursor_curr = $self->{cursor_curr}; ",
	    "cursor_limit = $self->{cursor_limit}\n";
    my $token = $class->_new( $content ) or return;
    $token->significant() and $self->{expect} = undef;
    $token->__PPIX_TOKEN__post_make( $self, $arg );

    $token->isa( TOKEN_UNKNOWN ) and $self->{failures}++;

    $self->{cursor_curr} += $length;
    $self->{find} = undef;
    $self->{match} = undef;
    $self->{capture} = undef;

    foreach my $name ( keys %{ $self->{cookie} } ) {
	my $cookie = $self->{cookie}{$name};
	$cookie->( $self, $token )
	    or delete $self->{cookie}{$name};
    }

    # Record this token as the prior token if it is significant. We must
    # do this after processing cookies, so that the cookies have access
    # to the old token if they want.
    $token->significant()
	and $self->{prior} = $token;

    return $token;
}

sub match {
    my ( $self ) = @_;
    return $self->{match};
}

sub modifier {
    my ( $self, $modifier ) = @_;
    return $self->{modifiers}[-1]{$modifier};
}

sub modifier_duplicate {
    my ( $self ) = @_;
    push @{ $self->{modifiers} },
	{ %{ $self->{modifiers}[-1] } };
    return;
}

sub modifier_modify {
    my ( $self, %args ) = @_;

    # Modifier code is centralized in PPIx::Regexp::Token::Modifier
    $self->{modifiers}[-1] =
	PPIx::Regexp::Token::Modifier::__PPIX_TOKENIZER__modifier_modify(
	$self->{modifiers}[-1], \%args );

    return;

}

sub modifier_pop {
    my ( $self ) = @_;
    @{ $self->{modifiers} } > 1
	and pop @{ $self->{modifiers} };
    return;
}

sub next_token {
    my ( $self ) = @_;

    {

	if ( @{ $self->{pending} } ) {
	    return shift @{ $self->{pending} };
	}

	if ( $self->{cursor_curr} >= $self->{cursor_limit} ) {
	    $self->{cursor_limit} >= length $self->{content}
		and return;
	    $self->{mode} eq 'finish' and return;
	    $self->{mode} = 'finish';
	    $self->{cursor_limit}++;
	}

	if ( my @tokens = $self->get_token() ) {
	    push @{ $self->{pending} }, @tokens;
	    redo;

	}

    }

    return;

}

sub peek {
    my ( $self, $offset ) = @_;
    defined $offset or $offset = 0;
    $offset < 0 and return;
    $offset += $self->{cursor_curr};
    $offset >= $self->{cursor_limit} and return;
    return substr $self->{content}, $offset, 1;
}

sub ppi_document {
    my ( $self ) = @_;

    defined $self->{find} or $self->_remainder();

    return PPI::Document->new( \"$self->{find}" );
}

sub prior {
    my ( $self, $method, @args ) = @_;
    defined $method or return $self->{prior};
    $self->{prior}->can( $method )
	or confess 'Programming error - ',
	    ( ref $self->{prior} || $self->{prior} ),
	    ' does not support method ', $method;
    return $self->{prior}->$method( @args );
}

sub significant {
    return 1;
}

sub tokens {
    my ( $self ) = @_;

    my @rslt;
    while ( my $token = $self->next_token() ) {
	push @rslt, $token;
    }

    return @rslt;
}

sub _remainder {
    my ( $self ) = @_;

    $self->{cursor_curr} > $self->{cursor_limit}
	and confess "Programming error - Trying to find past end of string";
    $self->{find} = substr(
	$self->{content},
	$self->{cursor_curr},
	$self->{cursor_limit} - $self->{cursor_curr}
    );

    return;
}

sub __PPIX_TOKENIZER__init {
    my ( $class, $tokenizer, $character ) = @_;

    $tokenizer->{mode} = 'kaput';
    $tokenizer->{content} =~ m/ \A \s* ( qr | m | s )? ( \s* ) ( [^\w\s] ) /smx
	or return $tokenizer->make_token(
	    length( $tokenizer->{content} ), TOKEN_UNKNOWN );
#   my ( $type, $white, $delim ) = ( $1, $2, $3 );
    my ( $type, $white ) = ( $1, $2 );
    my $start_pos = defined $-[1] ? $-[1] :
	defined $-[2] ? $-[2] :
	defined $-[3] ? $-[3] : 0;

    defined $type or $type = '';
    $tokenizer->{type} = $type;

    my @tokens;
    $start_pos
	and push @tokens, $tokenizer->make_token( $start_pos,
	'PPIx::Regexp::Token::Whitespace' );
    push @tokens, $tokenizer->make_token( length $type,
	'PPIx::Regexp::Token::Structure' );
    length $white > 0
	and push @tokens, $tokenizer->make_token( length $white,
	'PPIx::Regexp::Token::Whitespace' );

    {
	my @mods = @{ $tokenizer->{default_modifiers} };
	if ( $tokenizer->{content} =~ m/ ( [[:lower:]]* ) \s* \z /smx ) {
	    my $mod = $1;
	    $tokenizer->{cursor_limit} -= length $mod;
	    push @mods, $mod;
	}
	$tokenizer->{effective_modifiers} =
	    PPIx::Regexp::Token::Modifier::__aggregate_modifiers (
		@mods );
	$tokenizer->{modifiers} = [
	    { %{ $tokenizer->{effective_modifiers} } },
	];
	$tokenizer->{cursor_modifiers} = $tokenizer->{cursor_limit};
    }

    $tokenizer->{delimiter_start} = substr
	$tokenizer->{content},
	$tokenizer->{cursor_curr},
	1;

    if ( $type eq 's' and my $offset = $tokenizer->find_matching_delimiter() ) {
	$tokenizer->{cursor_limit} = $tokenizer->{cursor_curr} + $offset;
    } else {
	$tokenizer->{cursor_limit} = $tokenizer->{cursor_modifiers} - 1;
    }

    $tokenizer->{delimiter_finish} = substr
	$tokenizer->{content},
	$tokenizer->{cursor_limit},
	1;
    $tokenizer->{delimiter_re} = undef;

    push @tokens, $tokenizer->make_token( 1,
	'PPIx::Regexp::Token::Delimiter' );

    $tokenizer->{mode} = 'regexp';

    return @tokens;
}

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    my $mode = $tokenizer->{mode};
    my $handler = '__PPIX_TOKENIZER__' . $mode;

    $tokenizer->{cursor_orig} = $tokenizer->{cursor_curr};
    foreach my $class( $tokenizer->_known_tokenizers() ) {
	my @tokens = grep { $_ } $class->$handler( $tokenizer, $character );
	$tokenizer->{trace}
	    and warn $class, "->$handler( \$tokenizer, '$character' )",
		" => (@tokens)\n";
	@tokens
	    and return ( map {
		ref $_ ? $_ : $tokenizer->make_token( $_,
		    $class ) } @tokens );
    }

    # Find a fallback processor for the character.
    my $fallback = __PACKAGE__->can( '__PPIX_TOKEN_FALLBACK__' . $mode )
	|| __PACKAGE__->can( '__PPIX_TOKEN_FALLBACK__regexp' )
	|| confess "Programming error - unable to find fallback for $mode";
    return $fallback->( $class, $tokenizer, $character );
}

*__PPIX_TOKENIZER__repl = \&__PPIX_TOKENIZER__regexp;

sub __PPIX_TOKEN_FALLBACK__regexp {
    my ( $class, $tokenizer, $character ) = @_;

    # As a fallback in regexp mode, any escaped character is a literal.
    if ( $character eq '\\'
	&& $tokenizer->{cursor_limit} - $tokenizer->{cursor_curr} > 1
    ) {
	return $tokenizer->make_token( 2, TOKEN_LITERAL );
    }

    # Any normal character is unknown.
    return $tokenizer->make_token( 1, TOKEN_UNKNOWN );
}

sub __PPIX_TOKEN_FALLBACK__repl {
    my ( $class, $tokenizer, $character ) = @_;

    # As a fallback in replacement mode, any escaped character is a literal.
    if ( $character eq '\\'
	&& defined ( my $next = $tokenizer->peek( 1 ) ) ) {

	if ( $tokenizer->interpolates() || $next eq q<'> || $next eq '\\' ) {
	    return $tokenizer->make_token( 2, TOKEN_LITERAL );
	}
	return $tokenizer->make_token( 1, TOKEN_LITERAL );
    }

    # So is any normal character.
    return $tokenizer->make_token( 1, TOKEN_LITERAL );
}

sub __PPIX_TOKENIZER__finish {
    my ( $class, $tokenizer, $character ) = @_;

    $tokenizer->{cursor_limit} > length $tokenizer->{content}
	and confess "Programming error - ran off string";
    my @tokens = $tokenizer->make_token( 1,
	'PPIx::Regexp::Token::Delimiter' );

    if ( $tokenizer->{cursor_curr} eq $tokenizer->{cursor_modifiers} ) {

	# We are out of string. Make the modifier token and close up
	# shop.
	my $trailer;
	if ( $tokenizer->{content} =~ m/ \s+ \z /smx ) {
	    $tokenizer->{cursor_limit} = $-[0];
	    $trailer = length( $tokenizer->{content} ) -
		$tokenizer->{cursor_curr};
	} else {
	    $tokenizer->{cursor_limit} = length $tokenizer->{content};
	}
	push @tokens, $tokenizer->make_token(
	    $tokenizer->{cursor_limit} - $tokenizer->{cursor_curr},
	    'PPIx::Regexp::Token::Modifier' );
	if ( $trailer ) {
	    $tokenizer->{cursor_limit} = length $tokenizer->{content};
	    push @tokens, $tokenizer->make_token(
		$trailer, 'PPIx::Regexp::Token::Whitespace' );
	}
	$tokenizer->{mode} = 'kaput';

    } else {

	# Clear the cookies, because we are going around again.
	$tokenizer->{cookie} = {};

	# Move the cursor limit to just before the modifiers.
	$tokenizer->{cursor_limit} = $tokenizer->{cursor_modifiers} - 1;

	# If the preceding regular expression was bracketed, we need to
	# consume possible whitespace and find another delimiter.

	if ( $tokenizer->close_bracket( $tokenizer->{delimiter_start} ) ) {
	    my $accept;
	    $accept = $tokenizer->find_regexp( qr{ \A \s+ }smx )
		and push @tokens, $tokenizer->make_token(
		$accept, 'PPIx::Regexp::Token::Whitespace' );
	    my $character = $tokenizer->peek();
	    $tokenizer->{delimiter_start} = $character;
	    push @tokens, $tokenizer->make_token(
		1, 'PPIx::Regexp::Token::Delimiter' );
	    $tokenizer->{delimiter_finish} = substr
		$tokenizer->{content},
		$tokenizer->{cursor_limit} - 1,
		1;
	    $tokenizer->{delimiter_re} = undef;
	}

	if ( $tokenizer->modifier( 'e' ) ) {
	    # With /e, the replacement portion is code. We make it all
	    # into one big PPIx::Regexp::Token::Code, slap on the
	    # trailing delimiter and modifiers, and return it all.
	    push @tokens, $tokenizer->make_token(
		$tokenizer->{cursor_limit} - $tokenizer->{cursor_curr},
		'PPIx::Regexp::Token::Code',
		{ perl_version_introduced => MINIMUM_PERL },
	    );
	    $tokenizer->{cursor_limit} = length $tokenizer->{content};
	    push @tokens, $tokenizer->make_token( 1,
		'PPIx::Regexp::Token::Delimiter' );
	    push @tokens, $tokenizer->make_token(
		$tokenizer->{cursor_limit} - $tokenizer->{cursor_curr},
		'PPIx::Regexp::Token::Modifier' );
	    $tokenizer->{mode} = 'kaput';
	} else {
	    # Put our mode to replacement.
	    $tokenizer->{mode} = 'repl';
	}

    }

    return @tokens;

}

1;

__END__

=head1 NAME

PPIx::Regexp::Tokenizer - Tokenize a regular expression

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Tokenizer> is a
L<PPIx::Regexp::Support|PPIx::Regexp::Support>.

C<PPIx::Regexp::Tokenizer> has no descendants.

=head1 DESCRIPTION

This class provides tokenization of the regular expression.

=head1 METHODS

This class provides the following public methods. Methods not documented
here (or documented below under L</EXTERNAL TOKENIZERS>) are private,
and unsupported in the sense that the author reserves the right to
change or remove them without notice.

=head2 new

 my $tokenizer = PPIx::Regexp::Tokenizer->new( 'xyzzy' );

This static method instantiates the tokenizer. You must pass it the
regular expression to be parsed, either as a string or as a
L<PPI::Element|PPI::Element> of some sort. You can also pass optional
name/value pairs of arguments. The option names are specified B<without>
a leading dash. Supported options are:

=over

=item default_modifiers array_reference

This argument specifies default statement modifiers. It is optional, but
if specified must be an array reference. See the
L<PPIx::Regexp|PPIx::Regexp> L<new()|PPIx::Regexp/new> documentation for
the details.

=item encoding name

This option specifies the encoding of the string to be tokenized. If
specified, an C<Encode::decode> is done on the string (or the C<content>
of the PPI class) before it is tokenized.

=item trace number

Specifying a positive value for this option causes a trace of the
tokenization. This option is unsupported in the sense that the author
reserves the right to alter it without notice.

If this option is unspecified, the value comes from environment variable
C<PPIX_REGEXP_TOKENIZER_TRACE> (see L</ENVIRONMENT VARIABLES>). If this
environment variable does not exist, the default is 0.

=back

Undocumented options are unsupported.

The returned value is the instantiated tokenizer, or C<undef> if
instantiation failed. In the latter case a call to L</errstr> will
return the reason.

=head2 content

 print $tokenizer->content();

This method returns the string being tokenized. This will be the result
of the L<< PPI::Element->content()|PPI::Element/content >> method if the
object was instantiated with a L<PPI::Element|PPI::Element>.

=head2 default_modifiers

 print join ', ', @{ $tokenizer->default_modifiers() };

This method returns a reference to a copy of the array passed to the
C<default_modifiers> argument to L<new()|/new>. If this argument was not
used to instantiate the object, the return is a reference to an empty
array.

=head2 encoding

This method returns the encoding of the data being parsed, if one was
set when the class was instantiated; otherwise it simply returns undef.

=head2 errstr

 my $tokenizer = PPIx::Regexp::Tokenizer->new( 'xyzzy' )
     or die PPIx::Regexp::Tokenizer->errstr();

This static method returns an error description if tokenizer
instantiation failed.

=head2 failures

 print $tokenizer->failures(), " tokenization failures\n";

This method returns the number of tokenization failures encountered. A
tokenization failure is represented in the output token stream by a
L<PPIx::Regexp::Token::Unknown|PPIx::Regexp::Token::Unknown>.

=head2 modifier

 $tokenizer->modifier( 'x' )
     and print "Tokenizing an extended regular expression\n";

This method returns true if the given modifier character was found on
the end of the regular expression, and false otherwise.

=head2 next_token

 my $token = $tokenizer->next_token();

This method returns the next token in the token stream, or nothing if
there are no more tokens.

=head2 significant

This method exists simply for the convenience of
L<PPIx::Regexp::Dumper|PPIx::Regexp::Dumper>. It always returns true.

=head2 tokens

 my @tokens = $tokenizer->tokens();

This method returns all remaining tokens in the token stream.

=head1 EXTERNAL TOKENIZERS

This class does very little of its own tokenization. Instead the token
classes contain external tokenization routines, whose name is
'__PPIX_TOKENIZER__' concatenated with the current mode of the tokenizer
('regexp' for regular expressions, 'repl' for the replacement string).

These external tokenizers are called as static methods, and passed the
C<PPIx::Regexp::Tokenizer> object and the current character in the
character stream.

If the external tokenizer wants to make one or more tokens, it returns
an array containing either length in characters for tokens of the
tokenizer's own class, or the results of one or more L</make_token>
calls for tokens of an arbitrary class.

If the external tokenizer is not interested in the characters starting
at the current position it simply returns.

The following methods are for the use of external tokenizers, and B<are
not part of the public interface to this class.>

=head2 capture

 if ( $tokenizer->find_regexp( qr{ \A ( foo ) }smx ) ) {
     foreach ( $tokenizer->capture() ) {
         print "$_\n";
     }
 }

This method returns all the contents of any capture buffers from the
previous call to L</find_regexp>. The first element of the array (i.e.
element 0) corresponds to C<$1>, and so on.

The captures are cleared by L</make_token>, as well as by another call
to L</find_regexp>.

=head2 cookie

 $tokenizer->cookie( foo => sub { 1 } );
 my $cookie = $tokenizer->cookie( 'foo' );
 my $old_hint = $tokenizer->cookie( foo => undef );

This method either creates, deletes, or accesses a cookie.

A cookie is a code reference which is called whenever the tokenizer makes
a token. If it returns a false value, it is deleted. Explicitly setting
the cookie to C<undef> also deletes it.

When you call C<< $tokenizer->cookie( 'foo' ) >>, the current cookie is
returned. If you pass a new value of C<undef> to delete the token, the
deleted cookie (if any) is returned.

When the L</make_token> method calls a cookie, it passes it the tokenizer
and the token just made. If a token calls a cookie, it is recommended that
it merely pass the tokenizer, though of course the token can do whatever
it wants.

The cookie mechanism seems to be a bit of a crock, but it appeared to be
more work to fix things up in the lexer after the tokenizer got
something wrong.

The recommended way to write a cookie is to use a closure to store any
necessary data, and have a call to the cookie return the data; otherwise
the ultimate consumer of the cookie has no way to access the data. Of
course, it may be that the presence of the cookie at a certain point in
the parse is all that is required.

=head2 expect

 $tokenizer->expect( 'PPIx::Regexp::Token::Code' );

This method inserts a given class at the head of the token scan, for the
next iteration only. More than one class can be specified. Class names
can be abbreviated by removing the leading 'PPIx::Regexp::'.

The expectation lasts from the next time L</get_token> is called until
the next time L<make_token> makes a significant token, or until the next
C<expect> call if that is done sooner.

=head2 find_regexp

 my $end = $tokenizer->find_regexp( qr{ \A \w+ }smx );
 my ( $begin, $end ) = $tokenizer->find_regexp(
     qr{ \A \w+ }smx );

This method finds the given regular expression in the content, starting
at the current position. If called in scalar context, the offset from
the current position to the end of the matched string is returned. If
called in list context, the offsets to both the beginning and the end of
the matched string are returned.

=head2 find_matching_delimiter

 my $offset = $tokenizer->find_matching_delimiter();

This method is used by tokenizers to find the delimiter matching the
character at the current position in the content string. If the
delimiter is an opening bracket of some sort, bracket nesting will be
taken into account.

When searching for the matching delimiter, the back slash character is
considered to escape the following character, so back-slashed delimiters
will be ignored. No other quoting mechanisms are recognized, though, so
delimiters inside quotes still count. This is actually the way Perl
works, as

 $ perl -e 'qr<(?{ print "}" })>'

demonstrates.

This method returns the offset from the current position in the content
string to the matching delimiter (which will always be positive), or
undef if no match can be found.

=head2 get_token

 my $token = $tokenizer->make_token( 3 );
 my @tokens = $tokenizer->get_token();

This method returns the next token that can be made from the input
stream. It is B<not> part of the external interface, but is intended for
the use of an external tokenizer which calls it after making and
retaining its own token to look at the next token ( if any ) in the
input stream.

If any external tokenizer calls get_token without first calling
make_token, a fatal error occurs; this is better than the infinite
recursion which would occur if the condition were not trapped.

An external tokenizer B<must> return anything returned by get_token;
otherwise tokens get lost.

=head2 interpolates

This method returns true if the top-level structure being tokenized
interpolates; that is, if the delimiter is not a single quote.

=head2 make_token

 return $tokenizer->make_token( 3, 'PPIx::Regexp::Token::Unknown' );

This method is used by this class (and possibly by individual
tokenizers) to manufacture a token. Its arguments are the number of
characters to include in the token, and optionally the class of the
token. If no class name is given, the caller's class is used. Class
names may be shortened by removing the initial 'PPIx::Regexp::', which
will be restored by this method.

The token will be manufactured from the given number of characters
starting at the current cursor position, which will be adjusted.

If the given length would include characters past the end of the string
being tokenized, the length is reduced appropriately. If this means a
token with no characters, nothing is returned.

=head2 match

 if ( $tokenizer->find_regexp( qr{ \A \w+ }smx ) ) {
     print $tokenizer->match(), "\n";
 }

This method returns the string matched by the previous call to
L</find_regexp>.

The match is set to C<undef> by L</make_token>, as well as by another
call to L</find_regexp>.

=head2 modifier_duplicate

 $tokenizer->modifier_duplicate();

This method duplicates the modifiers on the top of the modifier stack,
with the intent of creating a locally-scoped copy of the modifiers. This
should only be called by an external tokenizer that is actually creating
a modifier scope. In other words, only when creating a
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure> token
whose content is '('.

=head2 modifier_modify

 $tokenizer->modifier_modify( name => $value ... );

This method sets new values for the modifiers in the local scope. Only
the modifiers whose names are actually passed have their values changed.

This method is intended to be called after manufacturing a
L<PPIx::Regexp::Token::Modifier|PPIx::Regexp::Token::Modifier> token,
and passed the results of its C<modifiers> method.

=head2 modifier_pop

 $tokenizer->modifier_pop();

This method removes the modifiers on the top of the modifier stack. This
should only be called by an external tokenizer that is ending a modifier
scope. In other words, only when creating a
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure> token
whose content is ')'.

Note that this method will never pop the last modifier item off the
stack, to guard against unmatched right parentheses.

=head2 peek

 my $character = $tokenizer->peek();
 my $next_char = $tokenizer->peek( 1 );

This method returns the character at the given non-negative offset from
the current position. If no offset is given, an offset of 0 is used.

If you ask for a negative offset or an offset off the end of the sting,
C<undef> is returned.

=head2 ppi_document

This method makes a PPI document out of the remainder of the string, and
returns it.

=head2 prior

 $tokenizer->prior( 'can_be_quantified' )
    and print "The prior token can be quantified.\n";

This method calls the named method on the most-recently-instantiated
significant token, and returns the result. Any arguments subsequent to
the method name will be passed to the method.

Because this method is designed to be used within the tokenizing system,
it will die horribly if the named method does not exist.

=head1 ENVIRONMENT VARIABLES

A tokenizer trace can be requested by setting environment variable
PPIX_REGEXP_TOKENIZER_TRACE to a numeric value other than 0. Use of this
environment variable is unsupported in the same sense that the C<trace>
option of L</new> is unsupported. Explicitly specifying the C<trace>
option to L</new> overrides the environment variable.

The real reason this is documented is to give the user a way to
troubleshoot funny output from the tokenizer.

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
