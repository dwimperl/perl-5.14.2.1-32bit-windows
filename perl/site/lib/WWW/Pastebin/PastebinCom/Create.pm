package WWW::Pastebin::PastebinCom::Create;

use warnings;
use strict;

our $VERSION = '0.004';

use Carp;
use URI;
use LWP::UserAgent;
use overload q|""| => sub { shift->paste_uri };

sub new {
    my $class = shift;
    croak "Must have even number of arguments to the constructor"
        if @_ & 1;

    my %args = @_;
    
    unless ( $args{timeout} ) {
        $args{timeout} = 30;
    }
    unless ( $args{ua} ) {
        $args{ua} = LWP::UserAgent->new(
            timeout => $args{timeout},
            agent   => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US;'
                        . ' rv:1.8.1.12) Gecko/20080207 Ubuntu/7.10 (gutsy)'
                        . ' Firefox/2.0.0.12',

        );
    }

    return bless \%args, $class;
}

sub paste {
    my $self = shift;
    croak "Must have even number of arguments to paste() method"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;

    unless ( defined $args{text} ) {
        $self->error( 'Missing or undefined `text` argument' );
        return;
    }

    # handle uri (deprecated argument)
    if ( exists $args{uri} )
    {
	($args{subdomain} ) = $args{uri} =~ m{http://(.+)\.pastebin\.com}
	  or croak( "can't parse URI parameter: $args{uri}\n" );

	delete $args{uri};
    }


    $self->paste_uri( undef );
    $self->error( undef );

    %args = (
        format  => 'text',
        expiry  => 'd',
        poster  => '',
        email   => '',
        %args,
    );



    my $valid_formats = $self->get_valid_formats;
    unless ( exists $valid_formats->{ $args{format} } ) {
        croak "Invalid syntax-highlight format was specified\n"
                . "Use ->get_valid_formats() method to get full list"
                . " of valid values";
    }

    # map onto expiration
    my %expire = ( f => 'n',
		   d => '1d',
		   m => '1m' );

    croak "Invalid `expiry` argument. Must be either 'f', 'd' or 'm'"
      if !exists $expire{$args{expiry}};

    $args{expiry} = $expire{ $args{expiry} };

    # map onto API parameters
    my %API = (
	        poster => 'paste_name',
		text   => 'paste_code',
		email  => 'paste_email',
		subdomain => 'paste_subdomain',
		private => 'paste_private',
		expiry  => 'paste_expire_date',
		format => 'paste_format',
	      );

    $args{$API{$_}} = delete $args{$_}
      foreach grep { defined $API{$_}} keys %args;

    my $uri = URI->new( 'http://pastebin.com/api_public.php' );

    my $response = $self->{ua}->post( $uri, \%args );

     if ( $response->is_success or $response->is_redirect ) {
        return $self->paste_uri( $response->content );
     }
     else {
         $self->error( $response->status_line );
         return;
     }
}

sub error {
    my $self = shift;
    if ( @_ ) {
        $self->{ ERROR } = shift;
    }
    return $self->{ ERROR };
}

sub paste_uri {
    my $self = shift;
    if ( @_ ) {
        $self->{ PASTE_URI } = shift;
    }
    return $self->{ PASTE_URI };
}

sub get_valid_formats {

    return {
	    abap => 'ABAP',
	    actionscript => 'ActionScript',
	    actionscript3 => 'ActionScript 3',
	    ada => 'Ada',
	    apache => 'Apache Log',
	    applescript => 'AppleScript',
	    apt_sources => 'APT Sources',
	    asm => 'ASM (NASM)',
	    asp => 'ASP',
	    autoit => 'AutoIt',
	    avisynth => 'Avisynth',
	    bash => 'Bash',
	    basic4gl => 'Basic4GL',
	    bibtex => 'BibTeX',
	    blitzbasic => 'Blitz Basic',
	    bnf => 'BNF',
	    boo => 'BOO',
	    bf => 'BrainFuck',
	    c => 'C',
	    c_mac => 'C for Macs',
	    cill => 'C Intermediate Language',
	    csharp => 'C#',
	    cpp => 'C++',
	    caddcl => 'CAD DCL',
	    cadlisp => 'CAD Lisp',
	    cfdg => 'CFDG',
	    klonec => 'Clone C',
	    klonecpp => 'Clone C++',
	    cmake => 'CMake',
	    cobol => 'COBOL',
	    cfm => 'ColdFusion',
	    css => 'CSS',
	    d => 'D',
	    dcs => 'DCS',
	    delphi => 'Delphi',
	    dff => 'Diff',
	    div => 'DIV',
	    dos => 'DOS',
	    dot => 'DOT',
	    eiffel => 'Eiffel',
	    email => 'Email',
	    erlang => 'Erlang',
	    fo => 'FO Language',
	    fortran => 'Fortran',
	    freebasic => 'FreeBasic',
	    gml => 'Game Maker',
	    genero => 'Genero',
	    gettext => 'GetText',
	    groovy => 'Groovy',
	    haskell => 'Haskell',
	    hq9plus => 'HQ9 Plus',
	    html4strict => 'HTML',
	    idl => 'IDL',
	    ini => 'INI file',
	    inno => 'Inno Script',
	    intercal => 'INTERCAL',
	    io => 'IO',
	    java => 'Java',
	    java5 => 'Java 5',
	    javascript => 'JavaScript',
	    kixtart => 'KiXtart',
	    latex => 'Latex',
	    lsl2 => 'Linden Scripting',
	    lisp => 'Lisp',
	    locobasic => 'Loco Basic',
	    lolcode => 'LOL Code',
	    lotusformulas => 'Lotus Formulas',
	    lotusscript => 'Lotus Script',
	    lscript => 'LScript',
	    lua => 'Lua',
	    m68k => 'M68000 Assembler',
	    make => 'Make',
	    matlab => 'MatLab',
	    matlab => 'MatLab',
	    mirc => 'mIRC',
	    modula3 => 'Modula 3',
	    mpasm => 'MPASM',
	    mxml => 'MXML',
	    mysql => 'MySQL',
	    text => 'None',
	    nsis => 'NullSoft Installer',
	    oberon2 => 'Oberon 2',
	    objc => 'Objective C',
	    'ocaml-brief' => 'OCalm Brief',
	    ocaml => 'OCaml',
	    glsl => 'OpenGL Shading',
	    oobas => 'Openoffice BASIC',
	    oracle11 => 'Oracle 11',
	    oracle8 => 'Oracle 8',
	    pascal => 'Pascal',
	    pawn => 'PAWN',
	    per => 'Per',
	    perl => 'Perl',
	    php => 'PHP',
	    'php-brief' => 'PHP Brief',
	    pic16 => 'Pic 16',
	    pixelbender => 'Pixel Bender',
	    plsql => 'PL/SQL',
	    povray => 'POV-Ray',
	    powershell => 'Power Shell',
	    progress => 'Progress',
	    prolog => 'Prolog',
	    properties => 'Properties',
	    providex => 'ProvideX',
	    python => 'Python',
	    qbasic => 'QBasic',
	    rails => 'Rails',
	    rebol => 'REBOL',
	    reg => 'REG',
	    robots => 'Robots',
	    ruby => 'Ruby',
	    gnuplot => 'Ruby Gnuplot',
	    sas => 'SAS',
	    scala => 'Scala',
	    scheme => 'Scheme',
	    scilab => 'Scilab',
	    sdlbasic => 'SdlBasic',
	    smalltalk => 'Smalltalk',
	    smarty => 'Smarty',
	    sql => 'SQL',
	    tsql => 'T-SQL',
	    tcl => 'TCL',
	    tcl => 'TCL',
	    teraterm => 'Tera Term',
	    thinbasic => 'thinBasic',
	    typoscript => 'TypoScript',
	    unreal => 'unrealScript',
	    vbnet => 'VB.NET',
	    verilog => 'VeriLog',
	    vhdl => 'VHDL',
	    vim => 'VIM',
	    visualprolog => 'Visual Pro Log',
	    vb => 'VisualBasic',
	    visualfoxpro => 'VisualFoxPro',
	    whitespace => 'WhiteSpace',
	    whois => 'WHOIS',
	    winbatch => 'Win Batch',
	    xml => 'XML',
	    xorg_conf => 'Xorg Config',
	    xpp => 'XPP',
	    z80 => 'Z80 Assembler',
	   };
}


1;

__END__

=head1 NAME

WWW::Pastebin::PastebinCom::Create - paste to L<http://pastebin.com> from Perl.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::Pastebin::PastebinCom::Create;

    my $paste = WWW::Pastebin::PastebinCom::Create->new;

    $paste->paste( text => 'lots and lost of text to paste' )
        or die "Error: " . $paste->error;

    print "Your paste can be found on $paste\n";

=head1 DESCRIPTION

The module provides means of pasting large texts into
L<http://pastebin.com> pastebin site.

=head1 CONSTRUCTOR

=head2 new

    my $paste = WWW::Pastebin::PastebinCom::Create->new;

    my $paste = WWW::Pastebin::PastebinCom::Create->new(
        timeout => 10,
    );

    my $paste = WWW::Pastebin::PastebinCom::Create->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new yummy juicy WWW::Pastebin::PastebinCom::Create
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 timeout

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for pasting. B<Defaults to:> C<30> seconds.

=head3 ua

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for pasting, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::Pastebin::PastebinCom::Create>'s C<timeout> argument is
set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 paste

    $paste->paste( text => 'long long text' )
        or die "Failed to paste: " . $paste->error;

    my $paste_uri = $paste->paste(
        text => 'long long text',
        format => 'perl',
        poster => 'Zoffix',
        expiry => 'm',
        subdomain => 'subdomain',
        private  => 0,
    ) or die "Failed to paste: " . $paste->error;

Instructs the object to pastebin some text. If pasting succeeded returns
a URI pointing to your paste, otherwise returns either C<undef> or
an empty list (depending on the context) and the reason for the failure
will be avalable via C<error()> method (see below).

Note: you don't have to store the return value. There is a C<paste_uri()>
method as well as overloaded construct; see C<paste_uri()> method's
description below.

Takes one mandatory and
three optional arguments which are as follows:

=head3 text

    ->paste( text => 'long long long long text to paste' );

B<Mandatory>. The C<text> argument must contain the text to paste. If
C<text>'s value is undefined the C<paste()> method will return either
C<undef> or an empty list (depending on the context) and the C<error()>
method will contain a message about undefined C<text>.

=head3 format

    ->paste( text => 'foo', format => 'perl' );

B<Optional>. Specifies the format of the paste to enable specific syntax
highlights on L<http://pastebin.com>. The list of possible values is
very long, see C<get_valid_formats()> method below for information
on how to obtain possible valid values for the C<format> argument.
B<Defaults to:> C<text> (plain text paste).

=head3 poster

    ->paste( text => 'foo', poster => 'Zoffix Znet' );

B<Optional>. Specifies the name of the person pasting the text.
B<Defaults to:> empty string, which leads to C<Anonymous> apearing on
L<http://pastebin.com>

=head3 expiry

    ->paste( text => 'foo', expiry => 'f' );

B<Optional>. Specifies when the paste should expire.
B<Defaults to:> C<d> (expire the paste in one day). Takes three possible
values:

=over 5

=item d

When C<expiry> is set to value C<d>, the paste will expire in one day.

=item m

When C<expiry> is set to value C<m>, the paste will expire in one month.

=item f

When C<expiry> is set to value C<f>, the paste will (should) stick around
"forever".

=back

=head3 C<subdomain>

    subdomain => 'private_domain'

B<Optional>. Allows one to paste into a so called "private" pastebin with a personal domain name. Takes the domain name.

=head3 C<uri>

    uri => 'http://private_domain.pastebin.com/'

B<DEPRECATED>. use C<subdomain>. 

=head2 error

    $paste->paste( text => 'foos' )
        or die "Error: " . $paste->error;

If the C<paste()> method failed to paste your text for any reason
(including your text being undefined) it will return either C<undef>
or an empty list depending on the context. When that happens you will
be able to find out the reason of the error via C<error()> method.
Returns a scalar containing human readable message describing the error.
Takes no arguments.

=head2 paste_uri (and overloads)

    print "You can find your pasted text on " . $paste->paste_uri . "\n";

    # or by interpolating the WWW::Pastebin::PastebinCom::Create object directly:
    print "You can find your pasted text on $paste\n";

Takes no arguments. Returns a URI pointing to the L<http://pastebin.com>
page containing the text you have pasted. If you call this method before
pasting anything or if C<paste()> method failed the C<paste_uri> will
return either C<undef> or an empty list depending on the context.

B<Note:> the WWW::Pastebin::PastebinCom::Create object is overloaded so instead
of calling C<paste_uri> method you could simply interpolate the
WWW::Pastebin::PastebinCom::Create object. For example:

    my $paster = WWW::Pastebin::PastebinCom::Create->new;
    $paster->paste( text => 'long text' )
        or die "Failed to paste: " . $paster->error;
        
    print "Your paste is located on $paster\n";

=head2 get_valid_formats

    my $valid_formats_hashref = $paste->get_valid_formats;

Takes no arguments. Returns a hashref, keys of which will be valid
values of the C<format> argument to C<paste()> method and values of which
will be explanation of semi-cryptic codes.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>, L<http://mind-power-book.com/>)

Patches by Diab Jerius (DJERIUS)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pastebin-pastebincom-create at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Pastebin-PastebinCom-Create>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Pastebin::PastebinCom::Create

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Pastebin-PastebinCom-Create>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Pastebin-PastebinCom-Create>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Pastebin-PastebinCom-Create>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Pastebin-PastebinCom-Create>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

