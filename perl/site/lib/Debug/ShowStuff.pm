package Debug::ShowStuff;
use strict;
# use Filter::HereDocIndent;
use Carp;
# use Data::Default ':all';
use Tie::IxHash;
use vars qw[$VERSION];

# version
$VERSION = '1.13';


# allow for forced context
# This is a change to how Debug::ShowStuff used to work.  It used to be that
# the output of a function (e.g. println) was returned as a scalar if the
# function call was made in an array context.  This got confusing when the
# call was the last call in a function.  I'm changing it so that, by default,
# the function always outputs to the standard file handle (usually STDOUT).
use vars qw[ $always_void ];
$always_void = 1;

# allow for forced web/plain
use vars qw[ $forceweb ];

# default $out to STDOUT
use vars qw[ $out ];
$out = *STDOUT;

# default $out to STDOUT
use vars qw[ $active ];
$active = 1;

# INDENT: how far to indent a line
our $indent_level = 0;
my $indent_tab = '   ';

# constants
use constant STDTABLE => qq|<p>\n<table border="4" rules="rows" cellspacing="0" cellpadding="3">\n|;


#---------------------------------------------------------------------
# export
# 
use vars qw[@EXPORT_OK %EXPORT_TAGS @ISA];
use Exporter;
push @ISA, 'Exporter';

@EXPORT_OK = qw[
	showhash showhashhtml showhashplain
	showarray showarr
	showarraydiv showarrdiv
	showcgi
	showscalar showsca
	showref
	showstderr
	setoutput
	pressenter
	inweb
	httpheader
	httpheaders
	println
	printnorm
	printhr
	preln
	dieln
	diearr
	fixundef
	diearr
	findininc
	confirm
	output_to_file
	define_show
	showtainted
	showstuff
	showsth
	indent
	timer
];

%EXPORT_TAGS = ('all' => [@EXPORT_OK]);
#
# export
#---------------------------------------------------------------------


#------------------------------------------------------------------------------
# opening POD
#

=head1 NAME

Debug::ShowStuff - A collection of handy debugging routines for displaying
the values of variables with a minimum of coding.

=head1 SYNOPSIS

Here's a sampling of a few of my favorite functions in this module.

	use Debug::ShowStuff ':all';
	
	# display values of a hash or hash reference
	showhash %hash;
	showhash $hashref;
	
	# display values of an array or array reference
	showarr @arr;
	showarr $arrref;
	
	# show all nested structures
	showref $reference
	
	# show all the params received through CGI
	showcgi();
	
	# A particularly fancy utility: display STDERR at top of web page
	my $warnings = showstderr;


=head1 INSTALLATION

C<Debug::ShowStuff> can be installed with the usual routine:

	perl Makefile.PL
	make
	make test
	make install

You can also just copy ShowStuff.pm into the Debug/ directory of one of your library trees.

=head1 DESCRIPTION

C<Debug::ShowStuff> grew dynamically from my needs in debugging code.  I found 
myself doing the same tasks over and over... displaying the keys and
values in a hash, displaying the elements in an array, displaying the output
of STDERR in a web page, etc.  C<Debug::ShowStuff> began as two or three of my
favorite routines and grew as I added to that collection.  Finally I decided
to publish these tools in the hope that other Perl hackers will find
them useful.

C<Debug::ShowStuff> is intended for debugging, not for production work.  I would
discourage anyone from using C<Debug::ShowStuff> in ready-for-primetime code.
C<Debug::ShowStuff> is only for quick-n-dirty displays of variable values in
order to debug your code.

These functions display values the way I personally like them displayed.  Your
preferences may be different.  I encourage you to modify C<Debug::ShowStuff>
to suit your own needs.

=head1 text and web modes

The functions in C<Debug::ShowStuff> are designed to output either in plain
text mode (like if you're running the script from a command prompt), or in web
mode (like from a CGI).  If the script appears to be running in a CGI or other
web mode (see the C<inweb> function) then values are output using HTML, with
special HTML characters escaped for proper display.  Othewise the values are
output as they are.

Generally you won't need to bother telling C<Debug::ShowStuff> if you're in
text or web mode... it figures it out on its own.

=head1 dynamic output/return: different than previous versions

NOTE: The dynamic behavior of "show" functions has changed since the last
version of Debug::ShowStuff.  "show" functions now always output to STDOUT
or STDERR unless $Debug::ShowStuff::always_void is set to false. By default
$always_void is true.

If $always_void is false, then the following applies:

The functions that start with "show" dynamically either output to STDOUT or
STDERR or return a string, depending on the context in which the
functions are called.  For example, if you call showhash in a void context:

  showhash %myhash;

then the contents of %myhash are output to STDOUT.  On the other hand, if the
function is called in scalar context:

  my $var = showhash(%myhash);

then the same string that would have been output to STDOUT is instead
returned and stored in $var.  

By default, output is sent to STDOUT, not STDERR.  You can change the
default output to STDERR using the C<setoutput> command.  See the docs
for that command for more detail.

=head1 Displaying "invisible" strings

To facilitate telling the difference between C<[undef]> and an empty string,
functions output the strings "[undef]" and "[empty string]".  So, for example,
this code:

 println undef;
 println "";

produces this:

 [undef]
 [empty string]

=head1 FUNCTION DESCRIPTIONS

=cut

#
# opening POD
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# default
#
# Private sub
#
sub default {
	for (my $i=0; $i<=$#_; $i++) {
		defined($_[$i]) and return $_[$i];
	}
	
	return undef;
}
#
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# showstuff
#

=head2 showstuff()

This function turns on/off most of the functions in this module, with one
import exception explained below.  The function also returns the state of
whether or not Debug::ShowStuff is on/off.

If a parameter is sent, that param is used to turn display on/off.  The
value is stored in the global variable $Debug::ShowStuff::active.

The function is also used by most subroutines to determine if they should
actually output anything.  $active is not the only criteria used to determine
if Debug::ShowStuff is active.  The algorithm is as follows:

- If the environment variable SHOWSTUFF is defined and false then this function
returns false regardless of the state of $active.

- If the environment variable $ENV{'SHOWSTUFF'} is not defined or is defined
and true then $active is used to determine on/off.

The purpose of this algorithm is to allow the used of debugging display in a
regression test but turn off those displays when a lot of tests are run at once
and only pass/fail information is needed from the regtest.

For example, suppose you have a script as follows:

 #!/usr/bin/perl -w
 use strict;
 use Debug::ShowStuff ':all';
 
 my ($rv);
 
 println 'running my_function()';
 $rv = my_function();
 println 'the returned value is: ', $rv;
 
 $rv or die 'error!';

The output of the script might look something like this:

 running my_function()
 1

Now suppose you call that and other scripts from some OTHER script, and
you don't want the screen cluttered with all that debugging, you just want
to see if all those scripts run successfully.  You could use $ENV{'SHOWSTUFF'}
to turn off showing stuff:

 #!/usr/bin/perl -w
 use strict;
 use Debug::ShowStuff ':all';
 
 my @tests = ("./script1.pl", "./script2.pl", "./script3.pl");
 $ENV{'SHOWSTUFF'} = 0;
 
 foreach my $test () {
    system($test) and die "$test failed";
 }

In that case, none of the stuff from the test scripts would be output.

=cut

sub showstuff {
	if (@_)
		{ $active = $_[0] }
	
	# if SHOWSTUFF environment variable is defined and false
	if ( defined($ENV{'SHOWSTUFF'}) && (! $ENV{'SHOWSTUFF'}) )
		{ return 0 }
	
	# else use $active
	return $active;
}
#
# showstuff
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# htmlesc
#
# Private sub.  Formats a string for literal output in HTML.  An undefined
# first argument is returned as an empty string.
#
sub htmlesc {
	my ($rv) = @_;
	return '' unless defined($rv);
	$rv =~ s|&|&#38;|g;
	$rv =~ s|"|&#34;|g;
	$rv =~ s|'|&#39;|g;
	$rv =~ s|<|&#60;|g;
	$rv =~ s|>|&#62;|g;
	return $rv;
}
#
# htmlesc
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# println
#

=head2 println

C<println> was the original Debug::ShowStuff function.  It simply outputs
the given values.

In text mode it adds a newline to the end.

For example, this code:

 println "hello world";

produces this output, including the newline:

 hello world

In web mode it puts the output inside a <p> element. The values are HTML
escaped so that HTML-significant characters like < and > are actually
displayed as < and >.  The <p> element has CSS styles set so that the
characters are always black, the background is always white, text is
left-aligned, and the <p> element has a black border, regardless
of the styles of the surrounding elements. So, for example, in web mode,
the following code:

 println 'whatever';

outputs the following HTML:

 <p style="background-color:white;color:black;text-align:left">whatever</p>

Like other "show" functions, undef is output as the string "[undef]" and
an empty string is output as the string "[empty string]".

Values in the arguments array are output concatenated together with no
spaces in between.  Each value is evaluated independently for if it
is undef, empty string, or a string with visible content.  So, for example,
this code:

 println "whatever", "", undef, "dude";

outputs this:

 whatever[empty string][undef]dude

=cut

sub println {
	showstuff() or return '';
	
	my ($str);
	my $fh = getfh(wantarray);
	
	# special case: no arguments: just output an eol and return
	if (! @_) {
		print $fh "\n";
		return;
	}
	
	# $str = join('', map {defined($_) ? $_ : '[undef]'} @_);
	$str = join('', map {define_show($_)} @_);
	
	# print as web page
	if (inweb()) {
		print $fh '<p style="background-color:white;color:black;text-align:left">', htmlesc($str), "</p>\n";
	}
	
	# else print as text
	# add indents at start and at every newline
	else {
		my ($indent);
		$indent = '';
		
		for (1..$indent_level)
			{ $indent .= $indent_tab }
		
		$str =~ s|\n|\n$indent|gs;
		$str = $indent . $str;
		
		print $fh $str, "\n";
	}
	
	ismem($fh) and return $fh->mem();
}
#
# println
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# showhash
#

=head2 showhash

Displays the keys and values in a hash.  Input is either a single hash
reference or a regular hash. The key=values pairs are sorted by the names
of the keys.

So, for example, the following code:

 my %hash = (
    Larry => 'curly headed guy',
    Curly => 'funny bald guy',
    Moe => 'guy in charge',
 );

 showhash %hash;

Produces the following output.  Notice that the keys are in alphabetic order:

 ---------------------------------------
 Curly = funny bald guy
 Larry = curly headed guy
 Moe   = guy in charge
 ---------------------------------------

This code, using a hash reference, produces exactly the same output:

 my $hash = {
    Larry => 'curly headed guy',
    Curly => 'funny bald guy',
    Moe => 'guy in charge',
 };

 showhash $hash;

If an undef value is sent instead of a hashref, then that fact is displayed
instead of a hash.  For example consider the following code that uses
a variable that is undef:

 my ($hash);
 showhash $hash;

That code produces this output:

 ---------------------------------------
 Only one element input and it was undefined
 ---------------------------------------

Optional arguments only come into play if the first argument is a hashref.

B<option:> title => "string"

If this option is sent, the string is displayed at the top of the
display of the hash values.

B<option:> line_cut => 1

If the C<line_cut> option is sent, then each value is truncated after the first
newline if there is one.

=cut

sub showhash {
	showstuff() or return '';
	
	# HTML
	if (inweb())
		{return showhashhtml(@_)}
	
	# plain text
	else
		{return showhashplain(@_)}
}
#
# showhash
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# showhashhtml
#
# Private sub. Displays the keys and values in a hash, formatted for HTML.
#
# Code in this sub is not indented because it uses a lot of here documents.
#
sub showhashhtml {

my %myhash;
my $maxkey = 0;
my $maxval = 0;
my $fh = getfh(wantarray);
my (%opts, $linecut, @keys);

print $fh STDTABLE;

# special case: only one element and it's undefined
if ( (@_ == 1) && (! defined($_[0])) ) {
	print $fh "<tr><td>Only element input and it was undefined</td></tr></table>\n";
	return;
}

if (ref $_[0]){
	%myhash = %{$_[0]};
	%opts = @_[1..$#_];
	$linecut = $opts{'line_cut'} || $opts{'line_chop'} || $opts{'first_line'};
}
else {
	%myhash = @_;
}

if (ref $_[0]) {
	my $title;
	
	if (defined $opts{'title'})
		{$title = $opts{'title'}}
	else
		{$title = $_[0]}
	
	print $fh '<tr><th colspan="3">', htmlesc($title), "</th></tr>\n"
}

print $fh <<"(TABLETOP2)";
<tr bgcolor="navy">
<th style="background-color:navy;color:white">key</th>
<td>&nbsp;&nbsp;&nbsp;</td>
<th style="background-color:navy;color:white">value</th>
</tr>
(TABLETOP2)

# get array of keys
@keys = keys(%myhash);

# sort keys unless sort param is sent as false
if (default $opts{'sort'}, 1) {
	@keys = sort { lc($a) cmp lc($b) } @keys;
}

# loop through keys, outputting key=value pairs
foreach my $key (@keys) {
	my $val = $myhash{$key};
	
	if ($linecut){
		$val =~ s|\n.*||s;
		$val .= '<b>...</b>';
	}
	
	print $fh
		'<tr valign="top">',
		'<td>', htmlesc($key), '</td>',
		'<td></td>',
		'<td>', htmlesc($val), '</td>',
		"</tr>\n";
}

# if empty hash, output that fact
if (! @keys) {
	print $fh
		'<tr>',
		'<td align="center" colspan="3"><i>empty hash</i></td>',
		"</tr>\n";
}

# close table
print $fh "</table>\n<p>\n";

ismem($fh) and return $fh->mem;
return '';
}
#
# showhashhtml
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# showhashplain
#
# Private sub. Displays the keys and values in a hash, formatted using plain text.
#
sub showhashplain {
	my %myhash;
	my $maxkey = 0;
	my $maxval = 0;
	my $fh = getfh(wantarray);
	my (%opts, $skipempty, %showfields, $linecut, $divider);
	
	# get title
	if (ref $_[0]) {
		%myhash = %{$_[0]};
		%opts = @_[1..$#_];
		
		if (defined $opts{'title'})
			{$divider = '--- ' . $opts{'title'} . ' ---------------------------------'}
	}
	
	if (! defined $divider)
		{ $divider = '---------------------------------------' }
	
	add_indents($fh);
	print $fh $divider, "\n";

	$divider =~ s|.|\-|gs;
	
	# special case: only one element and it's undefined
	if ( (@_ == 1) && (! defined($_[0])) ) {
		add_indents($fh);
		print $fh "Only one element input and it was undefined\n";
		add_indents($fh);
		print $fh $divider, "\n\n";
		
		ismem($fh) and return $fh->mem();
		return '';
	}
	
	# if first element is a reference, assume it's the hash to be displayed
	if (ref $_[0]){
		$linecut = $opts{'line_cut'} || $opts{'line_chop'} || $opts{'first_line'};
		$skipempty = $opts{'skipempty'};
		
		if (defined $opts{'showfields'}) {
			if (ref $opts{'showfields'})
				{@showfields{@{$opts{'showfields'}}} = ()}
			else
				{$showfields{ $opts{'showfields'} } = ()}
		}
	}
	
	# else all arguments form hash to be displayed
	else {
		%myhash = @_;
	}
	
	# if empty hash
	if (! keys(%myhash)) {
		add_indents($fh);
		print $fh "[empty hash]\n";
	}
	
	# not empty hash
	else {
		my ($keywidth, @keys);
		$keywidth = longestkey(\%myhash);
		
		@keys = keys(%myhash);
		
		# sort keys unless sort param is sent as false
		if (default $opts{'sort'}, 1) {
			@keys = sort { lc($a) cmp lc($b) } @keys;
		}
		
		# @keys = sort { lc($a) cmp lc($b) } @keys;

		KEYLOOP:
		foreach my $key (@keys) {
			# if there's a specified list of fields to show
			if ( %showfields && (! exists $showfields{$key}) )
				{next KEYLOOP}
			
			my $value = $myhash{$key};
			
			# if we should skip empty values
			if (
				$skipempty &&
					(
					(! defined $value) ||
					($value !~ m|\S|s)
					)
				)
				{next KEYLOOP}
			
			# linecut
			if ($linecut) {
				if ($value =~ s|[\r\n].*||s)
					{ $value .= ' [more lines...]' }
			}
			
			add_indents($fh);
			print $fh
				spacepad($key, $keywidth), ' = ',
				define_show($value), "\n";
		}

	}
	
	add_indents($fh);
	print $fh $divider, "\n\n";
	
	ismem($fh) and return $fh->mem();
	return '';
}
#
# showhashplain
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# showarr, showarray
#

=head2 showarr, showarray

Displays the values of an array.  c<showarr> and c<showarray>

Each element is displayed in a table row (in web mode) or on a separate line
(in text mode).

If C<showarray> receives exactly one argument, and if that item is an array
reference, then the routine assumes that you want to display the elements in
the referenced array. Therefore, the following blocks of code display the
same thing:

   showarray @myarr;
   showarray \@myarr;

=cut

sub showarray {
	showstuff() or return '';
	
	my (@arr) = @_;
	my $fh = getfh(wantarray);
	
	# if first and only element is an array ref, use that as full array
	if ( (@arr == 1) && UNIVERSAL::isa($arr[0], 'ARRAY') )
		{@arr = @{$arr[0]}}
	
	#------------------------------------------------------
	# HTML
	#
	if (inweb()) {
		print $fh 
			qq|<p>\n<table border="4" rules="rows" cellspacing="0" cellpadding="3">\n|,
			qq|<tr><th bgcolor="#aaaaff">array</th></tr>|;
		
		foreach my $el (@arr){
			print $fh '<tr><td>';
			
			if (defined $el){
				if ($el =~ m|\S|)
					{ print $fh htmlesc($el) }
				else
					{ print $fh '<i>no content string</i>' }
			}
			
			else {
				print $fh '<i>undefined</i>';
			}
			
			print $fh "</td></tr>\n";
		}
		
		print $fh qq|</table>\n<p>\n|;
	}
	#
	# HTML
	#------------------------------------------------------
	
	
	#------------------------------------------------------
	# text
	#
	else {
		my $line = "------------------------------------\n";
		my ($firstdone);
		
		add_indents($fh);
		print $fh $line;
		
		foreach my $el (@arr){
			add_indents($fh);
			print $fh define_show($el), "\n";
			
			$firstdone = 1;
		}
		
		
		if (! $firstdone) {
			add_indents($fh);
			print $fh "[empty array]\n";
		}
		
		add_indents($fh);
		print $fh $line;
	}
	#
	# text
	#------------------------------------------------------
	
	ismem($fh) and return $fh->mem();
}

sub showarr{showarray(@_)}
#
# showarr, showarray
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# showarrdiv
#

=head2 showarraydiv

Works just like C<showarray>, except that in text mode displays a solid line between
each element of the array.

=cut

sub showarraydiv {
	showstuff() or return '';
	
	my (@arr) = @_;
	my $fh = getfh(wantarray);
	
	if ( (@arr == 1) && UNIVERSAL::isa($arr[0], 'ARRAY') )
		{@arr = @{$arr[0]}}
	
	#------------------------------------------------------
	# HTML
	#
	if (inweb()) {
		print $fh 
			"<P>\n<TABLE BORDER=4 RULES=ROWS CELLSPACING=0 CELLPADDING=3>\n",
			"<TR><TH BGCOLOR=\"#AAAAFF\">array</TH></TR>";
		
		foreach my $el (@arr)
			{print $fh '<TR><TD>', htmlesc($el), "</TD></TR>\n"}
		
		print $fh "</TABLE>\n<P>\n";
	}
	#
	# HTML
	#------------------------------------------------------
	
	
	#------------------------------------------------------
	# text
	#
	else {
		my $line = "------------------------------------\n";
		my ($firstdone);
		
		print $fh $line;
		
		foreach my $el (@arr){
			#if (defined $el)
			#	{print $fh $el, "\n"}
			#else
			#	{print $fh "[undef]\n"}
			
			print $fh define_show($el);
			
			print $fh $line;
			$firstdone = 1;
		}
		
		if (! $firstdone)
			{print $fh "[empty array]\n", $line}
	}
	#
	# text
	#------------------------------------------------------
	
	ismem($fh) and return $fh->mem();
}

sub showarrdiv{showarraydiv(@_)}
#
# showarraydiv
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# showscalar
#

=head2 showscalar

Outputs the value of a scalar.  The name is slightly innaccurate: you can
input an array. The array will be joined together to form a single scalar.

Actually, I hardly ever use C<showscalar>, but it seemed unbalanced to have
C<showhash> and C<showarray> without C<showscalar>.

=cut

sub showscalar {
	showstuff() or return '';
	
	my (@arr) = @_;
	my $fh = getfh(wantarray);
	

	#------------------------------------------------------
	# HTML
	# 
	if (inweb()) {
		print $fh 
			"<P>\n<TABLE BORDER=4 RULES=ROWS CELLSPACING=0 CELLPADDING=3>\n",
			"<TR><TH BGCOLOR=\"#AAAAFF\">scalar</TH></TR><TR><TD><PRE>";
		
		foreach my $el (@arr)
			{print $fh htmlesc($el)}
		
		print $fh "</PRE></TD></TR></TABLE>\n<P>\n";
	}
	#
	# HTML
	#------------------------------------------------------
	
	
	#------------------------------------------------------
	# text
	#
	else {
		print $fh "------------------------------------\n";
		
		if (@arr) {
			print $fh
				join(
					'',
					map {define_show($_)}
					
					sort(
						{
							define_show($a) cmp
							define_show($b)
						} @arr
					)
				),
				
				"\n";
		}
		
		# {print $fh join('', map {defined($_) ? $_ : '[undef]'} sort({(defined($a) ? $a : '') cmp (defined($b) ? $b : '')} @arr)), "\n"}
		
		else {
			print $fh "[no elements]\n";
		}
		
		print $fh "------------------------------------\n";
	}
	#
	# text
	#------------------------------------------------------
	
	ismem($fh) and return $fh->mem();
}

sub showsca{showscalar(@_)}
#
# showscalar
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# showcgi
#

=head2 showcgi

Displays the CGI parameter keys and values.  This sub always outputs HTML.  

There are several optional parameters, described in the following sections.

B<option:> q

The optional parameter C<q>, may be a CGI query object:

   my $query = CGI->new();
   showcgi q => $query;

If C<q> is not sent, then a CGI object is created on the fly.

B<option:> skipempty

If the optional parameter C<skipempty> is true:

   showcgi skipempty => 1;

then CGI params that are empty (i.e. do not have
at least one non-space character) are not displayed.

B<option:> skip

C<skip> sets a list of parameters to not display.  For example, if you don't
want to see the C<choices> or C<toppings> params, then call showcgi like this:

   showcgi skip => ['choices', 'toppings'];

Single item lists can be passed in directly without putting them in
an anonymous array:

   showcgi skip => 'choices';

=cut

sub showcgi {
showstuff() or return '';

my (%opts) = @_;
my (@keys, $fh, $q, $skipempty, %skip);

$q = $opts{'r'} || $opts{'q'} || $opts{'cgi'} || CGI->new();
$skipempty = $opts{'skipempty'};

if (defined $opts{'skip'})
	{@skip{asarr($opts{'skip'})} = ()}

@keys = sort $q->param;
$fh = getfh(wantarray);

print $fh STDTABLE;

# title
print $fh <<"(TABLETITLE)";
<tr style="background-color:yellow">
<th style="color:black" colspan="3">CGI params</th>
</tr>
(TABLETITLE)


# special case: no elements
if (! @keys) {
	print $fh "<tr><td>No params</td></tr></table>\n";
	return;
}

print $fh <<"(TABLETOP2)";
<tr style="background-color:navy">
<th style="color:white">key</th>
<td>&nbsp;&nbsp;&nbsp;</td>
<th style="color:white">value</th>
</tr>
(TABLETOP2)

PARAMLOOP:
foreach my $key (@keys){
	my @vals = $q->param($key);
	
	if (exists $skip{$key})
		{next PARAMLOOP}
	
	if ($skipempty && @vals <= 1) {
		my $val = $vals[0];
		
		if ( (! defined $val) || ($val !~ m|\S|) )
			{next PARAMLOOP}
	}
	
	print $fh 
		'<tr valign="top"><td>',
		htmlesc($key),
		'</td><td></td><td>';
	
	if (@vals > 1) {
		print $fh STDTABLE;
		
		foreach my $val (@vals) {
			print $fh
				'<tr><td>',
				htmlesc($val),
				"</td></tr>\n";
		}
		
		print "</table>\n";
	}
	
	else {
		print $fh
			htmlesc($vals[0]);
	}
	
	print $fh "</td></tr>\n";
}

print $fh "</table>\n<p>\n";

ismem($fh) and return $fh->mem;
return '';
}
#
# showcgi
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# showref
#

=head2 showref($ref, %options)

Displays a hash, array, or scalar references, treeing down through other
references it contains.  So, for example, the following code:

 my $ob = {
    name    => 'Raha',
    email   => 'raha@idocs.com',
    friends => [
       'Shalom',
       'Joe',
       'Furocha',
       ],
    };
    
 showref $ob;

produces the following output:

   /-----------------------------------------------------------\
   friends =
      ARRAY
         Shalom
         Joe
         Furocha
   email = raha@idocs.com
   name = Raha
   \-----------------------------------------------------------/

The values of the hash or arrays being referenced are only displayed once, so
you're safe from infinite recursion. 

There are several optional parameters, described in the following sections.

B<option:> maxhash

The C<maxhash> option allows you to indicate the maximum number of hash
elements to display.  If a hash has more then C<maxhash> elements then none of
them are displayed or recursed through, and instead an indicator of how many
elements there are is output.  So, for example, the following command only
displays the hash values if there are 10 or fewer elements in the hash:

   showref $myob, maxhash=>10;
   

If C<maxhash> is not sent then there is no maximum.

B<option:> maxarr

The C<maxarr> option allows you to indicate the maximum number of array
elements to display.  If an array has more then C<maxarr> elements then none
of them are displayed or recursed through, and instead an indicator of how
many elements there are is output.  If C<maxarr> is not sent then there is no
maximum.

B<option:> depth

The C<depth> option allows you to indicate a maximum depth to display in the
tree. If C<depth> is not sent then there is no maximum depth.

B<option:> skip

A list of hash elements to skip.  Only applies to the top element and only if
it is a hash.

B<option:> skipall

Works the same as C<skip>, but applies to all hashes in the structure, not
just the top-level hash.

=cut

sub showref {
	showstuff() or return '';
	
	my ($ref, %opts) = @_;
	my ($indentnum, $indent, $type, $tab, %skip, $finalfh);
	my $fh = $opts{'fh'} || getfh(wantarray);
	
	
	# hash of keys to skip
	@skip{asarr(delete $opts{'skip'})} = ();
	@skip{asarr($opts{'skipall'})} = ();
	
	# set some variables
	$indentnum = $opts{'indent'};
	$indentnum ||= 0;
	$tab = '   ';
	$indent = $tab x $indentnum;
	$opts{'done'} ||= {};	
	
	$type = "$ref";
	$type =~ s|^[^\=]*\=||;
	$type =~ s|\(.*||;
	
	if (inweb())
		{print $fh qq|<pre style="text-align:left;">\n|}
	
	if (! $indent)
		{print $fh "/----------------------------------------------------------------------------\\\n"}
	
	if ($type eq 'HASH') {
		# if we've recursed to the maximum level
		if (
			$opts{'indent'} && 
			($opts{'indent'}>1) && 
			$opts{'maxhash'} && (keys(%{$ref}) > $opts{'maxhash'}) ) {
			my $count = keys %{$ref};
			
			print $fh
				$indent, '[', $count, ' hash element',
				($count>1 ? 's' : ''), "]\n";
		}

		# else we haven't recursed to the maximum level
		else {
			if ($opts{'labelself'}) {
				print $fh $indent, "HASH\n";
				$indentnum++;
				$indent .= $tab;
			}
			
			ELLOOP:
			while ( my($n, $v) = each(%{$ref}) ) {
				exists($skip{$n}) and next ELLOOP;
				
				print $fh $indent, $n, ' = ';
				
				if (ref $v) {
					if ( $opts{'depth'} ? ($opts{'depth'} >= $indentnum) : 1 ) {
						if ($opts{'done'}->{$v})
							{print $fh "[redundant]\n"}
						else {
							$opts{'done'}->{$v} = 1;
							print $fh "\n";
							showref($v, %opts, done=>$opts{'done'}, indent=>$indentnum+1, fh=>$fh)
						}
					}
					else 
						{print $fh $v}
				}
				
				#elsif (defined $v)
				#	{print $fh $v, "\n"}
				#else
				#	{print $fh "[undef]\n"}
				
				else {
					print $fh define_show($v);
				}
			}
		}
	}
	
	elsif ($type eq 'ARRAY') {
		print $fh $indent, "ARRAY\n";
		
		if ($opts{'maxarr'} && (@{$ref}) > $opts{'maxarr'} ) {
			print
				$indent, $tab, '[', scalar(@{$ref}), ' element',
				(@{$ref}>1 ? 's' : ''), "]\n";
		}
		
		else {
			my ($firstdone);
			
			foreach my $v ( @{$ref} ) {
				if (ref $v) {
					if ( $opts{'depth'} ? ($opts{'depth'} >= $indentnum) : 1 ) {
						if ($opts{'done'}->{$v})
							{print $fh $indent, $tab, '[redundant]'}
						else {
							$opts{'done'}->{$v} = 1;
							
							if ($firstdone)
								{print $fh "\n"}
							else
								{$firstdone = 1}
							
							showref($v, %opts, done=>$opts{'done'}, indent=>$indentnum+1, labelself=>1, fh=>$fh)
						}
					}
					else 
						{print $fh $indent, $tab, $v}
				}
				
				#elsif (defined $v)
				#	{print $fh $indent, $tab, $v, "\n"}
				#else
				#	{print $fh $indent, $tab, "[undef]\n"}
				
				else {
					print $fh $indent, $tab, define_show($v), "\n"
				}

			}
		}
	}
	
	if (! $indent)
		{print $fh "\\----------------------------------------------------------------------------/\n\n"}
	
	if (inweb())
		{print $fh "</pre>\n"}
	
	ismem($fh) and return $fh->mem();
}
# 
# showref
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# getfh
#
# Private sub.  Returns a file handle that is either STDOUT or STDERR (depending
# on the value of the global variable $Debug::ShowStuff::out), or a MemHandle
# object that will be used to return a string to the caller of the function
# that called getfh.
#
sub getfh {
	my ($wa) = @_;
	my ($fh);
	
	# if explicit context
	if (defined $always_void)
		{ undef $wa ;}
	
	# if called in void context, outputs to STDOUT,
	# otherwise returns string
	if (defined $wa) {
		require MemHandle;
	    $fh = MemHandle->new('');
	}
	
	else
		{$fh = $out}
	
	return $fh;
}
# 
# getfh
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ismem
#
# This private function returns true if the given file handle
# is a MemHandle filehandle.
#
sub ismem {
	return UNIVERSAL::isa($_[0], 'MemHandle');
}
#
# ismem
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# spacepad
#
# This private function returns the given string padded with
# the indicated number of spaces.  The spaces are added to the right
# 
sub spacepad {
	my ($str, $width) = @_;
	return sprintf("%-${width}s", $str);
}
#
# spacepad
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# longestkey
#
# This private function returns the length of the longest key
# in the given hash.  Only pass in hash references, not hashes.
#
sub longestkey {
	my ($hash) = @_;
	my $max = 0;
	
	foreach my $key (keys %$hash) {
		if (length($key) > $max)
			{ $max = length($key) }
	}
	
	return $max;
}
#
# longestkey
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# asarr
#
# Private function.  Allows an optional argument to be passed as
# either an array reference or as a single item.  Always returns
# an array reference in scalar context and an array in array context.
#
sub asarr {
	my $arg = shift;
	my @rv;
	
	if (ref $arg)
		{@rv = @$arg}
	elsif (defined $arg)
		{@rv = $arg}
	
	wantarray and return @rv;
	return \@rv;
}
#
# asarr
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# printhr
#

=head2 printhr

Prints a horizontal rule.  Handy for dividing up multiple println's.

In text mode, the horizontal rule is a set of 80 dashes.

In web mode, the output is an <hr> tag, unless the C<title> option is sent,
in which case the output is C<p> element with the title as the content. The
<p> element has a gray background and a black border.

B<option:> title

If the C<title>option is sent, the titleis embedded in the horizontal rule.

=cut

sub printhr {
	showstuff() or return '';
	my (%opts, $title);
	my $fh = getfh(wantarray);
	
	# single argument: title
	if (@_ == 1) {
		$title = $_[0];
	}
	else {
		%opts = @_;
		$title = $opts{'title'} || $opts{'msg'};
	}
	
	if (inweb()) {
		if (defined $title) {
print $fh <<"(HTML)";
<p
	style="
		background-color: #cccccc;
		border: 1px solid black;
		color: black;
		padding: 4px;
		font-weight: bold;
		font-size: 8pt;
		-moz-border-radius: 5px;
		-webkit-border-radius: 5px;
	">
@{ [ htmlesc($title) ] }
</p>
(HTML)
		}
		
		else {
			print $fh "<hr>\n";
		}
	}
	
	else {
		# set dash
		my $dash = default($opts{'dash'}, '-');
		
		add_indents($fh);
		
		if (defined $title) {
			print $fh
				($dash x 3),
				" $title ",
				($dash x (75 - length($title))),
				"\n";
		}
		
		else {
			print $fh ($dash x 80), "\n";
		}
	}
}
#
# asarr
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# add_indents
#
# Privae function
#
sub add_indents {
	my ($fh) = @_;
	
	for (1..$indent_level) {
		print $fh $indent_tab;
	}
}
#
# add_indents
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# printnorm
#

=head2 printnorm

Works like println but doesn't add trailing newline.  In web environment uses
<span> instead of <p>.

=cut

sub printnorm {
	showstuff() or return '';
	
	my ($str);
	my $fh = getfh(wantarray);
	
	# special case: no arguments: just output an eol and return
	if (! @_) {
		print $fh "\n";
		return;
	}
	
	# $str = join('', map {defined($_) ? $_ : '[undef]'} @_);
	$str = join('', map {define_show($_)} @_);
	
	
	if (inweb()) {
		print $fh '<span style="background-color:white;color:black;text-align:left">', htmlesc($str), "</span>";
	}
	else {
		add_indents($fh);
		print $fh $str;
	}
	
	ismem($fh) and return $fh->mem();
}
#
# printnorm
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# printval
#
# I don't even remember what this function is for, so for now I'm commenting
# it out.
#
# sub printval {
# 	showstuff() or return '';
# 	
# 	my ($val) = @_;
# 	my $fh = getfh(wantarray);
# 	
# 	# get value to print
# 	$val = define_show($val);
# 	
# 	if (inweb())
# 		{ $val = htmlesc($val) }
# 	
# 	print $fh $val;
# 	
# 	ismem($fh) and return $fh->mem();
# }
#
# printval
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# preln
#

=head2 preln

Outputs the given values inside a <pre> element.  Always outputs HTML.

=cut

sub preln {
	showstuff() or return '';
	
	my ($str);
	my $fh = getfh(wantarray);
	
	# special case: no inputs
	if (! @_ )
		{$str = '<i>empty</i>'}
	
	# special case: just one element and it's undefined
	elsif ( (@_ == 1) && (! defined $_[0]) )
		{$str = '<i>undefined</i>'}
	
	# else lump them all together
	else
		{$str = htmlesc(join('', @_))}
	
	print $fh
		'<pre style="background-color:white;color:black;text-align:left;border:gray solid 1px;margin:3px;padding:3px; font-size:16px;">',
		$str,
		"</pre>\n";
	
	ismem($fh) and return $fh->mem();
}
#
# preln
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# dieln
#

=head2 dieln

Works just like the C<die> command, except it always adds an end-of-line to
the input array so you never get those "at line blah-blah-blah" additions.

=cut

sub dieln {
	my ($str);
	$str = join('', map {define_show($_)} @_);
	
	die $str . "\n";
}
#
# dieln
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# diearr
#

=head2 diearr

Displays an array, then dies using C<dieln>.

=cut

sub diearr {
	my $err = shift;
	showarr @_;
	dieln $err;
}
#
# diearr
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# pressenter
#

=head2 pressenter

For use at the command line.  Outputs a prompt to "press enter to continue",
then waits for you to do exactly that.

=cut

sub pressenter {
	my ($msg) = @_;
	$msg ||= 'press enter to continue';
	$msg =~ s|\s*$| |s;
	
	print $msg;
	<STDIN>;
}
# 
# pressenter
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# confirm
#

=head2 confirm

Prompts the user for a y or n.  Exits quietly if y is pressed.

=cut

sub confirm {
	my ($msg) = @_;
	$msg ||= 'continue?';
	$msg =~ s|\s*$| |s;
	
	RESPONSELOOP:
	while (1) {
		my ($response);
		
		print $msg;
		$response = <STDIN>;
		$response =~ s|^\s*(.).*|$1|s;
		$response = lc($response);
		
		if ($response eq 'y')
			{ return 1 }
		elsif ($response eq 'n')
			{ exit }
	}
}
# 
# confirm
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# httpheader
#

=head2 httpheader

Outputs a text/html HTTP header.  Not useful if you're using mod_perl.

=cut

sub httpheader {
	my (%opts) = @_;
	
	if (wantarray)
		{return "Content-type:text/html\n\n"}
	
	my $fh = $opts{'fh'} || getfh(wantarray);
	print $fh "Content-type:text/html\n\n";
}

sub httpheaders{return httpheader(@_)}
#
# header
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# showstderr
#

=head2 showstderr

This function allows you to see, in the web page produced by a CGI, everything
the CGI output to STDERR. 

To use C<showstderr>, assign the return value of the function to a variable
that is scoped to the entire CGI script:

  my $stderr = showstderr();

You need not do anything more with that variable.  The object reference by
your variable holds on to everything output to both STDOUT and STDERR.  When
the variable goes out of scope, the object outputs the STDOUT content with the
STDERR content at the top of the web page.

=cut

sub showstderr {
	return Debug::ShowStuff::ShowStdErr->new(@_);
}
#
# showstderr
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# inweb
#

=head2 inweb

Returns a guess on if we're in a web environment.  The guess is pretty simple:
if the environment variable C<REQUEST_URI> is true (in the Perlish sense)
then this function returns true.

If the global C<$Debug::ShowStuff::forceweb> is defined, this function
returns the value of C<$Debug::ShowStuff::forceweb>.

=cut

sub inweb {
	if (defined $forceweb)
		{ return $forceweb }
	
	return ($ENV{'REQUEST_URI'} || $ENV{'SERVER_NAME'});
}
#
# inweb
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# output_to_file
#

=head2 output_to_file($path)

Sends Debug::ShowStuff output to a file instead of to STDOUT or STDERR.  The
value of this function MUST be assigned to a variable or it has no effect.
Don't do anything with the returned value... it is NOT a file handle.  The
returned value is an object that, when it goes out of scope, closes the output
file handle.

For example, the following code will output to three files names
Larry.txt, Curly.txt, and Moe.txt:

 foreach my $name (qw[Larry Curyl Moe]) {
    my $output = output_to_file("$name.txt");
    println $name;
    println 'length: ', length($name);
 }

=cut

sub output_to_file {
	my ($path) = @_;
	my ($fh, $closer);
	
	if (! defined wantarray) {
		my $msg =
			"Do not call outputfile in void context.  Save the return value to a scalar.\n" .
			"REMINDER: The return value is NOT a filehandle, it is just an object that, when\n" .
			"it goes out of scope, closes the global filehandle.\n";
		
		croak $msg;
	}
	
	require FileHandle;
	
	$fh = FileHandle->new(">$path");
	$fh->autoflush(1);
	
	setoutput($fh);
	
	$closer = Debug::ShowStuff::CloseGlobalHandle->new($fh);
	return $closer;
}
#
# output_to_file
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# setoutput
#

=head2 setoutput

Sets the default output handle.  By default, routines in C<Debug::ShowStuff>
output to STDOUT.  With this command you can set the default output to STDERR,
or back to STDOUT.  The following command sets default output to STDERR:

   setoutput 'stderr';

This command sets output back to STDOUT:

   setoutput 'stdout';

When default output is set to STDERR then the global
C<$Debug::ShowStuff::forceplain> is set to true, which means that functions in
this module always output in text mode, not web mode.

=cut

sub setoutput {
	my ($outname) = @_;
	
	# filehandle
	if ( UNIVERSAL::isa($outname, 'FileHandle') ) {
		$out = $outname;
		$forceweb = 0;
	}
	
	# STDOUT
	elsif (lc($outname) eq 'stdout') {
		$out = *STDOUT;
		undef $forceweb;
	}
	
	# STDERR
	elsif (lc($outname) eq 'stderr') {
		$out = *STDERR;
		$forceweb = 0;
	}
	
	# else don't know
	else
		{croak "do not know this type of output: $outname"}
}
#
# setoutput
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# fixundef
#

=head2 fixundef

Takes a single argument.  If that argument is undefined, returns an
empty string.  Otherwise returns the argument exactly as it is.

=cut

sub fixundef {
	defined($_[0]) or return '';
	return $_[0];
}
#
# fixundef
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# findininc
#

=head2 findininc

Given one or more file names, searches @INC for where they are located.
Returns an array of full file names.

=cut

sub findininc {
	my (@filenames) = @_;
	my (@rv);
	
	foreach my $dir (@INC) {
		foreach my $filename (@filenames) {
			my $path = "$dir/$filename";
			
			if (-e $path)
				{push @rv, $path}
		}
	}
	
	if (! defined(wantarray))
		{showarr @rv}
	else
		{return @rv}
}
#
# findininc
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# define_show
#
# Private function.  If the given value is undef, returns the string "[undef]".
# If it is an empty string, returns "[empty string]". Otherwise the original
# string is returned.
#
use overload;

sub define_show {
	my ($val) = @_;
	
	# if overloaded object, get return value and
	# concatenate with string (which defines it).
	if (ref $val) {
		if (my $func = overload::Method($val, '""'))
			{ $val = &$func($val) }
	}
	
	if (defined $val) {
		if ($val eq '')
			{ $val = '[empty string]' }
	}
	
	else {
		$val = '[undef]';
	}
	
	return $val;
}
#
# define_show
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# showtainted
#

=head2 showtainted(@values)

Given an array of values, shows which are tainted and which are not.  If the
first argument is a hashref, displays the tainted status of each element value.

=cut

sub showtainted {
	my (@vals) = @_;
	# require Taint;
	require Scalar::Util;
	
	# if first value is a hashref, show as hash
	if (UNIVERSAL::isa $vals[0], 'HASH') {
		my $hashref = $vals[0];
		my $show = {};
		
		while ( my($key, $val) = each(%$hashref) ) {
			my ($tainted);
			
			if (Scalar::Util::tainted($val))
				{ $tainted = 'tainted' }
			else
				{ $tainted = 'not tainted' }
			
			$show->{$key} = $tainted;
		}
		
		showhash $show;
	}
	
	# loop through values
	else {
		foreach my $val (@vals) {
			my ($tainted);
			
			if (Scalar::Util::tainted($val))
				{ $tainted = 'tainted:     ' }
			else
				{ $tainted = 'not tainted: ' }
			
			$val = "$tainted$val";
		}
		# show values
		showarr @vals;
	}
}
#
# showtainted
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# showsth
#

=head2 showsth

Outputs a  table of all rows in the given DBI statement handle.  Note that
this function "uses up" the statement handle.

NOTE: The text mode version of this function has not been fully implemented.

=cut

sub showsth {
	showstuff() or return '';
	
	if (inweb())
		{ return showsth_web(@_) }
	else
		{ return showsth_text(@_) }
}
#
# showsth
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# showsth_text
#
# Private subroutine. Text version of the system for showing a statement
# handle.
#
# NOTE: This subroutine has not been fully implemented.
#
sub showsth_text {
	my ($sth, %opts) = @_;
	my (@field_defs, @records, $full_row);
	my $fh = getfh(wantarray);
	
	# build hash of field names
	foreach my $field_name (@{$sth->{'NAME'}}) {
		my $def = {};
		push @field_defs, $def;
		
		# hold on to name
		$def->{'name'} = $field_name;
		
		# hold on to max length
		$def->{'max_length'} = length($field_name);
	}
	
	# loop through statement handle collecting fields
	while (my $row = $sth->fetchrow_hashref) {
		my $row_norm = {};
		
		# get max lengths
		foreach my $def (@field_defs) {
			my $val = $row->{$def->{'name'}};
			$val = define_show($val);
			
			# set maximum length
			if ( $def->{'max_length'} < length($val) )
				{ $def->{'max_length'} = length($val) }
			
			# normalized field value
			$row_norm->{$def->{'name'}} = $val;
		}
		
		push @records, $row_norm;
	}
	
	# begin header row
	$full_row = '+';
	
	# output headers
	foreach my $def (@field_defs) {
		my $field_name = uc $def->{'name'};
		
		while (length($field_name) < $def->{'max_length'})
			{ $field_name .= '-' }
		
		$full_row .= '-' . $field_name . '-+';
	}
	
	# close header row
	add_indents($fh);
	print $fh "$full_row\n";
	
	# output records
	foreach my $record (@records) {
		add_indents($fh);
		print $fh '|';
		
		# output each field
		foreach my $def (@field_defs) {
			my $val = $record->{$def->{'name'}};
			
			# space pad
			while ( length($val) < $def->{'max_length'} )
				{ $val .= ' ' }
			
			print $fh ' ', $val, ' |';
		}
		
		# close row
		print $fh "\n";
	}
	
	# bottom row
	$full_row =~ s|[^+]|-|gs;
	add_indents($fh);
	print $fh "$full_row\n";
	
	# success
	return '';
}
#
# showsth_text
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# showsth_web
#
sub showsth_web {
	my ($sth, %opts) = @_;
	my ($first_row_done, %field_names, $formats);
	tie %field_names, 'Tie::IxHash';
	$formats = $opts{'formats'} || {};
	
	# get headers that are to be output first
	if ($opts{'headers'}) {
		foreach my $field_name (@{$opts{'headers'}})
			{ undef $field_names{$field_name} }
	}
	
	# open table
print <<'(HTML)';
<table border="1" cellpadding="3">
(HTML)
	
	# output title if available
	if (defined $opts{'title'}) {
		print
			'<tr style="background-color:navy; color:white; text-align:left;">',
			'<th colspan="',
			scalar(@{$sth->{'NAME'}}),
			'">',
			$opts{'title'},
			"</th></tr>\n";
	}
	
	# loop through records
	while (my $row = $sth->fetchrow_hashref) {
		if (! $first_row_done) {
			# build list of headers
			foreach my $field_name (@{$sth->{'NAME'}}) {
				if (! exists $field_names{$field_name})
					{ undef $field_names{$field_name} }
			}
			
			# open table and header row
print <<'(HTML)';
<thead>
<tr valign="top" style="background-color:#99ccff; color:black; text-align:left;">
(HTML)
			
			# output headers
			foreach my $field_name (keys %field_names) {
				print '<th>', htmlesc($field_name), "</th>\n";
			}
			
			# close header row
print <<'(HTML)';
		</tr>
	</thead>
	<tbody>
(HTML)
			
			# note table headers have been output
			$first_row_done = 1;
		}
		
		# open row
		print '<tr style="background-color:white; color:black; text-align:left; vertical-align:top;">';
		
		# loop through fields
		foreach my $field_name (keys %field_names) {
			my ($value, $format);
			$value = $row->{$field_name};
			$format = $formats->{$field_name} || {};
			
			# <td>
			if ($format->{'align'})
				{ print qq|<td align="$format->{'align'}">| }
			else
				{ print '<td>' }
			
			if (defined $value) {
				if ($value eq '') {
					print '<i>[empty string]</i>';
				}
				
				else {
					my $output = htmlesc($value);
					
					# pre
					if ($format->{'pre'}) {
						$output =~ s|\t|    |gs;
						$output = "<pre>$output</pre>";
					}
					
					print $output;
				}
			}
			
			else {
				print '<i>[undef]</i>';
			}
			
			print "</td>\n";
		}
		
		# close row
		print "</tr>\n";
	}
	
	# close table or mention that there were no records
	if ($first_row_done) {
		print qq|</tbody>\n|;
	}
	
	else {
		print qq|</thead><tbody><tr><td>no records</td></tr>\n</tbody>\n|;
	}
	
	print qq|<table>\n|;
}
#
# showsth_web
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# indent
#

=head2 indent()

C<indent()> is for situations where you're outputting a lot of stuff and you
want to tidy up the list by indenting some of the output.  Currently
C<indent()> only has an effect in text mode.  It does nothing in web mode.

C<indent()> b<must be assigned to a variable> or it has no effect.  C<indent()>
increases the indent level by one.  When the variable goes out of scope, the
indent level is decreased by one.

For example suppose you want to display the values of records from a database.
You might loop through the records, outputting them like this:

 while (my $record = $sth->fetchrow_hashref) {
    println $record->{'name_nick'};
    my $indent = indent();
    showhash $record;
 }

That would produce output something like this:

 Ricky
   ---------------------------------------
   name_first  = Rick
   name_last   = Adams
   name_middle = Horatio
   name_nick   = Ricky
   salary      = $15,000
   ---------------------------------------

 Dan
   ---------------------------------------
   name_first  = Daniel
   name_last   = Bradley
   name_middle = [undef]
   name_nick   = Dan
   salary      = $250,000
   ---------------------------------------

By default, three spaces are used to indent. To change that set
$Debug::ShowStuff::indent_tab to whatever string you want to use for
indentation.

B<option:> bottom_space

The C<bottom_space> option indicates to output an extra line at the bottom
of the indented output, just to give some extra division before the next
batch of code.  For example, the following code does not use C<bottom_space>:

 foreach my $name (qw[Larry Moe]) {
    println $name;
    my $indent = indent(bottom_space=>1);
    println 'length: ', length($name);
 }

and so produces the following output:

 Larry
    length: 5
 Moe
    length: 3

But this code:

 foreach my $name (qw[Larry Moe]) {
    println $name;
    my $indent = indent(bottom_space=>1);
    println 'length: ', length($name);
 }

produces this output:

 Larry
    length: 5

 Moe
    length: 3


=cut

sub indent {
	my (%opts) = @_;
	$indent_level++;
	return Debug::ShowStuff::Indent->new(%opts);
}
#
# indent
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# timer
#

=head1 timer();

This function is useful for when you want to display how long it took for your
code to run.  Assign the return value of this function to a variable.  When the
variable goes out of scope then the difference between the start and end time is
displayed in seconds.  For example, the following code:

 do {
    my $timer = timer();
    sleep 3;
 };

outputs this:

 start timer
 duration: 3 seconds

B<option:> title

If you send the C<title> option, then that title will be displayed with the
beginning and ending output.  For example, this code:

 do {
    my $timer = timer(title=>'my block');
    sleep 3;
 };

produces this output:

 start timer - my block
 duration - my block: 3 seconds


=cut

sub timer {
	my (%opts) = @_;
	return Debug::ShowStuff::Timer->new(%opts);
}
#
# timer
#------------------------------------------------------------------------------



###############################################################################
# ShowStdErr
#
package Debug::ShowStuff::ShowStdErr;
require 5.005; # require at least Perl version 5.005
use strict;


#---------------------------------------------------------------------------
# new
#
sub new {
	my ($class, %opts) = @_;
	my $self = bless({}, $class);
	
	# default to HTML environment if environment appears to indicate so
	if ( (! defined $opts{'html'}) && $ENV{'REQUEST_URI'})
		{$opts{'html'} = 1}
	
	# default certain properties based on html
	if ($opts{'html'}) {
		defined($opts{'flushtostderr'}) or $opts{'flushtostderr'} = 1;
		defined($opts{'stderrfirst'})   or $opts{'stderrfirst'} = 1;
	}
	
	# default to output STDERR first
	$opts{'stderrfirst'} = exists($opts{'stderrfirst'}) ? $opts{'stderrfirst'} : 1;
	
	# other properties
	$self->{'html'} = $opts{'html'};
	$self->{'flushtostderr'} = $opts{'flushtostderr'};
	$self->{'stderrfirst'} = $opts{'stderrfirst'};
	
	# capture STDERR
	$self->{'stderrdata'} = {'str' => []};
	open(SAVEERR, ">&STDERR") or warn "Cannot save STDERR: $!\n";
	print SAVEERR '';
	$self->{'saveerr'} = *SAVEERR;
	$self->{'caperr'} = tie(*STDERR, $class . '::HandleOb', $self->{'stderrdata'}, %opts);
	
	# capture STDOUT
	if ($opts{'stderrfirst'}) {
		$self->{'stdoutdata'} = {'str' => []};
		
		open(SAVESTD, ">&STDOUT") or warn "Cannot save STDOUT: $!\n";
		print SAVESTD '';
		$self->{'savestd'} = *SAVESTD;
		$self->{'capstd'} = tie(*STDOUT, $class . '::HandleOb', $self->{'stdoutdata'}, %opts);
	}
	
	# warn() doesn't seem to print to STDERR through Perl.  
	# Catch that manually.
	$self->{'oldwarn'} = $SIG{__WARN__};
	$SIG{__WARN__}= sub {print STDERR "@_"};
	
	return $self;
}
#
# new
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# displaystderr
#
sub displaystderr {
	my ($self) = @_;
	
	# early exit: if there isn't anything in STDERR, do nothing
	unless (@{$self->{'stderrdata'}->{'str'}})
		{return}
	
	# output to the real STDERR if necessary
	if ($self->{'flushtostderr'})
		{print STDERR join("\n",@{$self->{'stderrdata'}->{'str'}})}
	
	# output as HTML if set to do so
	if ($self->{'html'}) {
		print 
			'<DIV STYLE="border-style:solid;border-width:1;padding:5;background-color:CCCCCC;color:black;">',
			"<H2 STYLE=\"margin-top:0px;\">STDERR</H2>\n<PRE>\n";
		
		foreach my $line (@{$self->{'stderrdata'}->{'str'}}) {
			# escape the HTML
			$line =~ s|&|&#38;|g;
			$line =~ s|"|&#34;|g;
			$line =~ s|'|&#39;|g;
			$line =~ s|<|&#60;|g;
			$line =~ s|>|&#62;|g;
			
			# output the line
			print $line;
		}
		
		print "</PRE>\n</DIV>\n\n";
	}
	
	# else output as text
	else {
		print 
			"========================================================================\n",
			"STDERR\n\n", 
			@{$self->{'stderrdata'}->{'str'}}, "\n",
			"========================================================================\n";
	}

}
#
# displaystderr
#---------------------------------------------------------------------------


#------------------------------------------------------------------------------
# DESTROY
#
DESTROY {
	my ($self) = @_;
	
	#------------------------------------------------
	# release handles
	#
	$SIG{__WARN__} = $self->{'oldwarn'};
	
	undef $self->{'caperr'}; # as documented in "perltie"
	untie(*STDERR)  or warn("Cannot untie STDERR: $!\n");
	
	# open(STDERR, ">&SAVEERR") or warn("Cannot restore STDERR: $!\n");
	*SAVEERR = $self->{'saveerr'};
	open(STDERR, ">&SAVEERR") or warn("Cannot restore STDERR: $!\n");
	
	if ($@)
		{die "$@"}
	
	# if also capturing stdout
	if ($self->{'stdoutdata'}) {
		undef $self->{'capstd'}; # as documented in "perltie"
		untie(*STDOUT) or warn("Cannot untie STDOUT: $!\n");
		
		*SAVESTD = $self->{'savestd'};
		open(STDOUT, ">&SAVESTD") or warn("Cannot restore STDOUT: $!\n");
		
		if ($@)
			{die "$@"}
	}
	#
	# release handles
	#------------------------------------------------
	
	
	#------------------------------------------------
	# display data
	# 
	if ($self->{'stderrfirst'}) {
		# put STDOUT into string
		my $stdout = join('', @{$self->{'stdoutdata'}->{'str'}});
		
		# if HTML
		if ($self->{'html'}) {
			my ($headers);
			
			# pull out headers
			# this part is a little kludgy
			# I couldn't get the split on the following line
			# to work quite right
			# ($headers, $stdout) = split(m/(\r\n\r\n)/s, $stdout, 2);
			$headers = $stdout;
			$headers =~ s/((?:\r\n\r\n)|(?:\n\n)|(?:\r\r)).*//s;
			$stdout = substr($stdout, length($headers) + length($1));
			
			# output headers
			print $headers, "\n\n";
		}
		
		# output stderr
		$self->displaystderr;
		
		# if stdout has any content, and it doesn't end in
		# a newline, add a newline
		if (  length($stdout) && ($stdout !~ m|[\r\n]$|)  )
			{$stdout .= "\n"}
		
		# output stdout
		print $stdout;
	}

	# else just output STDERR
	else {
		$self->displaystderr;
	}
	#
	# display data
	#------------------------------------------------

}
#
# DESTROY
#------------------------------------------------------------------------------


#
# ShowStdErr
###############################################################################



###############################################################################
# HandleOb
#
package Debug::ShowStuff::ShowStdErr::HandleOb;
use strict;
use Carp;


sub TIEHANDLE {
	my($class, $data, %opts) = @_;
	my $self= bless( {} , $class);
	
	$self->{'croakonerr'} = $opts{'croakonerr'};
	$self->{'data'} = $data;
	
	return($self);
}

sub WRITE {
	my($self, $buf, $len, $offset) = @_;
	push @{$self->{'data'}->{'str'}}, $buf;
	return 1;
}

sub PRINT {
	my $self = shift;
	
	# croak if necessary
	if ($self->{'croakonerr'})
		{croak @_}

	push @{$self->{'data'}->{'str'}}, @_;

	return 1;
}

sub PRINTF {
	my $self = shift;
	my $fmt = shift;
	
	# $self->{'data'}->{'str'} .= sprintf($fmt, @_);
	push @{$self->{'data'}->{'str'}}, sprintf($fmt, @_);

	
	return 1;
}

sub AUTOLOAD {
}

sub readwarning {
	carp "Cannot read from specified filehandle.";
}

#
# HandleOb
###############################################################################



###############################################################################
# CloseGlobalHandle
#
# Private function.
# Objects in this class automatically undefs Debug::ShowStuff::out if it is
# a FileHandle object;
#
# Objects in this class are used by the function output_to_file().
#
package Debug::ShowStuff::CloseGlobalHandle;
use strict;
# use Carp;

#------------------------------------------------------------------------------
# new
#
sub new {
	my ($class, $fh) = @_;
	my $self = bless {}, $class;
	
	$self->{'fh'} = $fh;
	return $self;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# DESTROY
#
DESTROY {
	my ($self) = @_;
	my $global = $Debug::ShowStuff::out;
	
	# if the global output filehandle still exists
	if ($global) {
		
		# if it's a filehandle object
		if ( UNIVERSAL::isa($global, 'FileHandle') ) {
			
			# if it's the same filehandle object as this object references
			if ($global == $self->{'fh'}) {
				# print "closing $global\n";
				
				undef $global;
				undef $Debug::ShowStuff::out;
				Debug::ShowStuff::setoutput('stdout');
			}
		}
	}

}
#
# DESTROY
#------------------------------------------------------------------------------



#
# CloseGlobalHandle
###############################################################################



###############################################################################
# Indent
#
# An object in this class for the purpose of decrementing the current
# indent level when it is destroyed.  On destruction is decrements 
# $Debug::ShowStuff::indent_level.
#
package Debug::ShowStuff::Indent;
use strict;


#---------------------------------------------------------------------------
# new
#
sub new {
	my ($class, %opts) = @_;
	my $indent = bless({%opts}, $class);
	return $indent;
}
#
# new
#---------------------------------------------------------------------------


#------------------------------------------------------------------------------
# DESTROY
#
DESTROY {
	my ($self) = @_;
	
	# add bottom space if necessary
	if ($self->{'bottom_space'})
		{ Debug::ShowStuff::println() }
	
	if ($Debug::ShowStuff::indent_level > 0 )
		{ $Debug::ShowStuff::indent_level-- }
}
#
# DESTROY
#------------------------------------------------------------------------------


#
# CloseIndent
###############################################################################



###############################################################################
# Timer
#
# An object in this class for the purpose of showing the amount of time
# something took to run.  When the object is initialized it notes the current
# time.  When it is destroyed is displays the number of seconds between when
# it was created and when it was destroyed.
#
package Debug::ShowStuff::Timer;
use strict;


#---------------------------------------------------------------------------
# new
#
sub new {
	my ($class, %opts) = @_;
	my $timer = bless({%opts}, $class);
	
	# hold on to start time
	$timer->{'start'} = time();
	
	# note beginning of duration
	if (defined $timer->{'title'}) {
		Debug::ShowStuff::println('start timer - ', $timer->{'title'});
	}
	else {
		Debug::ShowStuff::println('start timer');
	}
	
	# return
	return $timer;
}
#
# new
#---------------------------------------------------------------------------


#------------------------------------------------------------------------------
# DESTROY
#
DESTROY {
	my ($timer) = @_;
	my ($duration);
	
	# get duration
	$duration = time() - $timer->{'start'};
	
	# note beginning of duration
	if (defined $timer->{'title'}) {
		Debug::ShowStuff::println(
			'duration - ',
			$timer->{'title'},
			': ',
			$duration,
			' seconds',
		);
	}
	else {
		Debug::ShowStuff::println(
			'duration : ',
			$duration,
			' seconds',
		);
	}
}
#
# DESTROY
#------------------------------------------------------------------------------


#
# Timer
###############################################################################




__END__


=head1 TERMS AND CONDITIONS

Copyright (c) 2010 by Miko O'Sullivan.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHORS

Miko O'Sullivan
F<miko@idocs.com>

=head1 VERSION

=over

=item Version 1.00    May 29, 2003

Initial public release.

=item Version 1.01    May 29, 2003

Setting sort order of hash keys to case insensitive.

=item Version 1.10    Nov 6, 2010

After seven years, decided to update the version on CPAN.

=item Version 1.11    Nov 13, 2010

Fixed prerequisite requirement for MemHandle and Taint. Added timer()
functions.  Some minor documentation fixes and tidying up.

=item Version 1.12    Nov 29, 2010

Changing from using Taint module, which has had a lot of problems, to
Scalar::Util, which is more (but not completely) stable.

=item Version 1.13    Dec 1, 2010

Fixed bug in prerequisites for Scalar::Util.

=back

=cut


# return true
1;
