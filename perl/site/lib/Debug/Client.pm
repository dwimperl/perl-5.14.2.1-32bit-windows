package Debug::Client;

use 5.008005;
use strict;
use warnings;

our $VERSION = '0.16';

use utf8;
use IO::Socket;
use Carp qw(carp croak cluck);

use constant {
	BLANK => qq{ },
};

=head1 NAME

Debug::Client - client side code for perl debugger

=head1 SYNOPIS

  use Debug::Client;
  my $debugger = Debug::Client->new(host => $host, port => $port);
  $debugger->listener;

Where $host is the host-name to be used by the script under test (SUT)
to access the machine where Debug::Client runs. If they are on the same machine
this should be C<localhost>.
$port can be any port number where the Debug::Client could listen.

This is the point where the external SUT needs to be launched 
by first setting 
     
  $ENV{PERLDB_OPTS} = "RemotePort=$host:$port"

then running

  perl -d script

Once the script under test was launched we can call the following:

  my $out = $debugger->get;

  $out = $debugger->step_in;

  $out = $debugger->step_over;


  my ($prompt, $module, $file, $row, $content) = $debugger->step_in;
  my ($module, $file, $row, $content, $return_value) = $debugger->step_out;
  my $value = $debugger->get_value('$x');

  $debugger->run();         # run till end of breakpoint or watch
  $debugger->run( 42 );     # run till line 42  (c in the debugger)
  $debugger->run( 'foo' );  # run till beginning of sub

  $debugger->execute_code( '$answer = 42' );

  $debugger->execute_code( '@name = qw(foo bar)' );

  my $value = $debugger->get_value('@name');  $value is the dumped data?

  $debugger->execute_code( '%phone_book = (foo => 123, bar => 456)' );

  my $value = $debugger->get_value('%phone_book');  $value is the dumped data?
  
  
  $debugger->set_breakpoint( "file", 23 ); # set breakpoint on file, line

  $debugger->get_stack_trace

Other planned methods:

  $debugger->set_breakpoint( "file", 23, COND ); # set breakpoint on file, line, on condition
  $debugger->set_breakpoint( "file", subname, [COND] )

  $debugger->set_watch
  $debugger->remove_watch
  $debugger->remove_breakpoint


  $debugger->watch_variable   (to make it easy to display values of variables)

=head2 example

  my $script = 'script_to_debug.pl';
  my @args   = ('param', 'param');
  
  my $perl = $^X; # the perl might be a different perl
  my $host = 'localhost';
  my $port = 24642;
  my $pid = fork();
  die if not defined $pid;
  
  if (not $pid) {
	local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port"
  	exec("$perl -d $script @args");
  }
  
  
  require Debug::Client;
  my $debugger = Debug::Client->new(
    host => $host,
    port => $port,
  );
  $debugger->listener;
  my $out = $debugger->get;
  $out = $debugger->step_in;
  # ...

=head1 DESCRIPTION

=cut

=head2 new

The constructor can get two parameters: host and port.

  my $debugger = Debug::Client->new;

  my $debugger = Debug::Client->new(host => 'remote.hots.com', port => 24642);
   
Immediately after the object creation one needs to call

  $debugger->listener;
  
TODO: Is there any reason to separate the two?

=cut

sub new {
	my ( $class, %args ) = @_;
	my $self = bless {}, $class;

	%args = (
		host => 'localhost', port => 24642,
		%args
	);

	$self->{host} = $args{host};
	$self->{port} = $args{port};

	return $self;
}

=head1 Warning sub listen has bean deprecated

Has bean deprecated since 0.13_04 and all future versions starting with v0.14

Perl::Critic Error Subroutine name is a homonym for built-in function

Use $debugger->listener instead

=cut

# sub listen {
# my ( $self, @args ) = @_;
# $self->listener(@args);
# return;
# }

=head2 listener

listener/hearken To listen attentively; give heed.

See C<new>

 $debugger->listener

=cut

#######
# Method listener
#######
sub listener {
	my ($self) = @_;

	# Open the socket the debugger will connect to.
	my $sock = IO::Socket::INET->new(
		LocalHost => $self->{host},
		LocalPort => $self->{port},
		Proto     => 'tcp',
		Listen    => SOMAXCONN,

		# Reuse     => 1,	#(deprecated, prefer ReuseAddr)
		ReuseAddr => 1,
	);
	$sock or carp "Could not connect to '$self->{host}' '$self->{port}' no socket :$!";
	_logger("listening on '$self->{host}:$self->{port}'");
	$self->{sock} = $sock;

	$self->{new_sock} = $self->{sock}->accept();

	return;
}

=head2 buffer

Returns the content of the buffer since the last command

  $debugger->buffer;

=cut

#######
# Method buffer
#######
sub buffer {
	my ($self) = @_;
	return $self->{buffer};
}

=head2 quit

 $debugger->quit();

=cut

#######
# Method quit
#######
sub quit {
	my $self = shift;
	return $self->_send('q');
}

=head2 show_line

.

Return the internal debugger pointer to the line last executed, and print out that line.

 $debugger->show_line();

=cut

#######
# Method show_line
#######
sub show_line {
	my $self = shift;

	# return $self->_send_get('.');
	$self->_send('.');
	my $buf = $self->_get;

	$self->_prompt( \$buf );
	return $buf;
}

=head2 show_view

v [line]

View a few lines of code around the current line.

 $debugger->show_view();

=cut

#######
# Method show_line
#######
sub show_view {
	my $self = shift;

	# return $self->_send_get('.');
	$self->_send('v');
	my $buf = $self->_get;

	$self->_prompt( \$buf );
	return $buf;
}



=head2 step_in

s [expr]

Single step. 
Executes until the beginning of another statement, descending into subroutine calls. 
If an expression is supplied that includes function calls, it too will be single-stepped.

 $debugger->step_in();

Expressions not supported. 

=cut

#######
# Method step_in
#######
sub step_in {
	my $self = shift;
	return $self->_send_get('s');
}

=head2 step_over

 $debugger->step_over();

=cut

#######
# Method step_over
#######
sub step_over {
	my $self = shift;
	return $self->_send_get('n');
}

=head2 step_out

 my ($prompt, $module, $file, $row, $content, $return_value) = $debugger->step_out();

Where $prompt is just a number, probably useless

$return_value  will be undef if the function was called in VOID context

It will hold a scalar value if called in SCALAR context

It will hold a reference to an array if called in LIST context.

TODO: check what happens when the return value is a reference to a complex data structure
or when some of the elements of the returned array are themselves references

=cut

sub step_out {
	my ($self) = @_;

	carp('Must call step_out in list context') if not wantarray;

	$self->_send('r');
	my $buf = $self->_get;

	# void context return from main::f
	# scalar context return from main::f: 242
	# list  context return from main::f:
	# 0 22
	# 1 34
	# main::(t/eg/02-sub.pl:9):	my $z = $x + $y;

	# list context return from main::g:
	# 0  'baz'
	# 1  'foo
	# bar'
	# 2  'moo'
	# main::(t/eg/03-return.pl:10):	$x++;

	$self->_prompt( \$buf );
	my @line = $self->_process_line( \$buf );
	my $ret;
	my $context;
	if ( $buf =~ /^(scalar|list) context return from (\S+):\s*(.*)/s ) {
		$context = $1;
		$ret     = $3;
	}

	#if ($context and $context eq 'list') {
	# TODO can we parse this inteligently in the general case?
	#}
	return ( @line, $ret );
}


=head2 get_stack_trace

Sends the stack trace command C<T> to the remote debugger
and returns it as a string if called in scalar context.
Returns the prompt number and the stack trace string
when called in array context.

=cut

#T Produce a stack backtrace.
sub get_stack_trace {
	my ($self) = @_;
	$self->_send('T');
	my $buf = $self->_get;

	$self->_prompt( \$buf );
	return $buf;
}

=head2 toggle_trace

Sends the stack trace command C<t> Toggle trace mode.

 $debugger->toggle_trace();

=cut

#######
# sub toggle_trace
#######
sub toggle_trace {
	my ($self) = @_;

	$self->_send('t');
	my $buf = $self->_get;

	$self->_prompt( \$buf );
	return $buf;
}

=head2 list_subroutine_names

Sends the stack trace command C<S> [[!]pattern] 
List subroutine names [not] matching pattern.

=cut

#######
# sub list_subroutine_names
#######
sub list_subroutine_names {
	my ( $self, $pattern ) = @_;

	if ( defined $pattern ) {
		$self->_send("S $pattern");
	} else {
		$self->_send('S');
	}

	my $buf = $self->_get;

	$self->_prompt( \$buf );
	return $buf;
}

=head2 run

  $debugger->run;
  
Will run till the next breakpoint or watch or the end of
the script. (Like pressing c in the debugger).

  $debugger->run($param)

=cut

sub run {
	my ( $self, $param ) = @_;
	if ( not defined $param ) {
		return $self->_send_get('c');
	} else {
		return $self->_send_get("c $param");
	}

}


=head2 set_breakpoint

 $debugger->set_breakpoint($file, $line, $condition);

=cut

sub set_breakpoint {
	my ( $self, $file, $line, $cond ) = @_;

	$self->_send("f $file");

	# $self->_send("b $file");
	my $b = $self->_get;

	# print $b . "\n";

	# Already in t/eg/02-sub.pl.

	$self->_send("b $line");

	# if it was successful no reply
	# if it failed we saw two possible replies
	my $buf = $self->_get;

	# print $buf . "\n";
	my $prompt = $self->_prompt( \$buf );
	if ( $buf =~ /^Subroutine [\w:]+ not found\./ ) {

		# failed
		return 0;
	} elsif ( $buf =~ /^Line \d+ not breakable\./ ) {

		# faild to set on line number
		return 0;
	} elsif ( $buf =~ /\S/ ) {
		return 0;
	}

	return 1;
}

=head2 remove_breakpoint

 $debugger->remove_breakpoint( $self, $file, $line );

=cut

# apparently no clear success/error report for this
sub remove_breakpoint {
	my ( $self, $file, $line ) = @_;

	$self->_send("f $file");
	my $b = $self->_get;

	$self->_send("B $line");
	my $buf = $self->_get;
	return 1;
}

=head2 show_breakpoints

The data as (L) prints in the command line debugger.

 $debugger->show_breakpoints();

=cut

#######
# show_breakpoints
#######
sub show_breakpoints {
	my ($self) = @_;

	my $ret = $self->_send_get('L');

	return $ret;
}

=head2 list_break_watch_action

In scalar context returns the list of all the breakpoints 
and watches as a text output. The data as (L) prints in the
command line debugger.

In list context it returns the prompt number,
and a list of hashes. Each hash has

  file =>
  line =>
  cond => 

to provide the file-name, line number and the condition of the breakpoint.
In case of no condition the last one will be the number 1.

=cut

sub list_break_watch_action {
	my ($self) = @_;

	my $ret = $self->_send_get('L');
	if ( not wantarray ) {
		return $ret;
	}

	# short cut for direct output
	# return $ret;

	# t/eg/04-fib.pl:
	#  17:      my $n = shift;
	#    break if (1)
	my $buf    = $self->buffer;
	my $prompt = $self->_prompt( \$buf );

	my @breakpoints;
	my %bp;
	my $PATH = qr{[\w./-]+};
	my $LINE = qr{\d+};
	my $CODE = qr{.*}s;
	my $COND = qr{1};       ## TODO !!!

	while ($buf) {
		if ( $buf =~ s{^($PATH):\s*($LINE):\s*($CODE)\s+break if \(($COND)\)s*}{} ) {
			my %bp = (
				file => $1,
				line => $2,
				cond => $4,
			);
			push @breakpoints, \%bp;
		} else {
			carp "No breakpoint found in '$buf'";
		}
	}

	return ( $prompt, \@breakpoints );
}

=head2 execute_code

  $debugger->execute_code($some_code_to_execute);

=cut

sub execute_code {
	my ( $self, $code ) = @_;

	return if not defined $code;

	$self->_send($code);
	my $buf = $self->_get;
	$self->_prompt( \$buf );
	return $buf;
}

=head2 get_value

 my $value = $debugger->get_value($x);

If $x is a scalar value, $value will contain that value.
If it is a reference to a SCALAR, ARRAY or HASH then $value should be the
value of that reference?

=cut

# TODO if the given $x is a reference then something (either this module
# or its user) should actually call   x $var
sub get_value {
	my ( $self, $var ) = @_;

	if ( not defined $var ) {
		$self->_send('p');
		my $buf = $self->_get;
		$self->_prompt( \$buf );
		return $buf;
	} elsif ( $var =~ /\@/ or $var =~ /\%/ ) {
		$self->_send("x \\$var");
		my $buf = $self->_get;
		$self->_prompt( \$buf );
		my $data_ref = _parse_dumper($buf);
		return $data_ref;
	} else {
		$self->_send("p $var");
		my $buf = $self->_get;
		$self->_prompt( \$buf );
		return $buf;
	}
}

=head2 get_p_exp

p expr

Same as print {$DB::OUT} expr in the current package. 
In particular, because this is just Perl's own print function, 
this means that nested data structures and objects are not dumped, 
unlike with the x command.

The DB::OUT filehandle is opened to /dev/tty, 
regardless of where STDOUT may be redirected to.
From perldebug, but defaulted to y 0

  $debugger->get_p_exp();

=cut

#######
# sub get_p_exp
#######
sub get_p_exp {
	my ( $self, $exp ) = @_;

	$self->_send("p $exp");
	my $buf = $self->_get;
	$self->_prompt( \$buf );
	return $buf;
}

=head2 get_y_zero

From perldebug, but defaulted to y 0

 y [level [vars]]

Display all (or some) lexical variables (mnemonic: mY variables) in the current 
scope or level scopes higher. You can limit the variables that you see with vars 
which works exactly as it does for the V and X commands. Requires the PadWalker 
module version 0.08 or higher; will warn if this isn't installed. 
Output is pretty-printed in the same style as for V and the format is controlled by the same options.

  $debugger->get_y_zero();

=cut

#######
# sub get_y_zero
#######
sub get_y_zero {
	my $self = shift;

	$self->_send("y 0");
	my $buf = $self->_get;
	$self->_prompt( \$buf );
	return $buf;
}

=head2 get_v_vars

V [pkg [vars]]

Display all (or some) variables in package (defaulting to main ) 
using a data pretty-printer (hashes show their keys and values so you see what's what, 
control characters are made printable, etc.). 
Make sure you don't put the type specifier (like $ ) there, just the symbol names, like this:

 $debugger->get_v_vars(regex);

=cut

#######
# sub get_v_vars
#######
sub get_v_vars {
	my ( $self, $pattern ) = @_;

	if ( defined $pattern ) {
		$self->_send("V $pattern");
	} else {
		$self->_send('V');
	}
	my $buf = $self->_get;
	$self->_prompt( \$buf );
	return $buf;
}

=head2 get_x_vars

X [vars] Same as V currentpackage [vars]

 $debugger->get_v_vars(regex);

=cut

#######
# sub get_x_vars
#######
sub get_x_vars {
	my ( $self, $pattern ) = @_;

	if ( defined $pattern ) {
		$self->_send("X $pattern");
	} else {
		$self->_send('X');
	}

	my $buf = $self->_get;
	$self->_prompt( \$buf );
	return $buf;
}

=head2 get_h_var

Enter h or `h h' for help,
For more help, type h cmd_letter, optional var

 $debugger->get_h_var();

=cut

#######
# sub get_h_var
#######
sub get_h_var {
	my ( $self, $var ) = @_;

	if ( defined $var ) {
		$self->_send("h $var");
	} else {
		$self->_send('h');
	}

	my $buf = $self->_get;
	$buf =~ s/(\e\[4m|\e\[24m|\e\[1m|\e\[0m)//mg;
	$self->_prompt( \$buf );
	return $buf;
}

=head2 set_option

o booloption ...

Set each listed Boolean option to the value 1 .
o anyoption? ...

Print out the value of one or more options.
o option=value ...

Set the value of one or more options. If the value has internal whitespace, it should be quoted. For example, you could set o pager="less -MQeicsNfr" to call less with those specific options. You may use either single or double quotes, but if you do, you must escape any embedded instances of same sort of quote you began with, as well as any escaping any escapes that immediately precede that quote but which are not meant to escape the quote itself. In other words, you follow single-quoting rules irrespective of the quote; eg: o option='this isn\'t bad' or o option="She said, \"Isn't it?\"" .

For historical reasons, the =value is optional, but defaults to 1 only where it is safe to do so--that is, mostly for Boolean options. It is always better to assign a specific value using = . The option can be abbreviated, but for clarity probably should not be. Several options can be set together. See Configurable Options for a list of these.

 $debugger->set_option();

=cut

#######
# Internal Method _set_option
#######
sub set_option {
	my ( $self, $option ) = @_;

	unless ( defined $option ) {
		return;
	}

	$self->_send("o $option");
	my $buf = $self->_get;
	$self->_prompt( \$buf );
	return $buf;

}

=head2 get_options

o

Display all options.

 $debugger->get_options();

=cut

#######
# Internal Method _get_options
#######
sub get_options {
	my $self = shift;

	$self->_send('o');
	my $buf = $self->_get;
	$self->_prompt( \$buf );
	return $buf;

}

=head2 get

Actually I think this is an internal method....

In SCALAR context will return all the buffer collected since the last command.

In LIST context will return ($prompt, $module, $file, $row, $content)
Where $prompt is the what the standard debugger uses for prompt. Probably not too
interesting.
$file and $row describe the location of the next instructions.
$content is the actual line - this is probably not too interesting as it is 
in the editor. $module is just the name of the module in which the current execution is.

=cut

sub get {
	my ($self) = @_;

	my $buf = $self->_get;

	if (wantarray) {
		$self->_prompt( \$buf );
		my ( $module, $file, $row, $content ) = $self->_process_line( \$buf );
		return ( $module, $file, $row, $content );
	} else {
		return $buf;
	}
}


=head2 filename

 $debugger->filename();

=cut

#######
# Method filename
#######
sub filename {
	my $self = shift;

	return $self->{filename};
}

=head2 row

 $debugger->row();

=cut

#######
# Method row
#######
sub row {
	my $self = shift;

	return $self->{row};
}

=head2 module

 $debugger->module();

=cut

#######
# Method module
#######
sub module {
	my $self = shift;

	return $self->{module};
}
#########################################
#### Internal Methods
#######
# Internal Method _get
#######
# TODO shall we add a timeout and/or a number to count down the number
# sysread calls that return 0 before deciding it is really done
sub _get {
	my ($self) = @_;

	#my $remote_host = gethostbyaddr($sock->sockaddr(), AF_INET) || 'remote';
	my $buf = q{};
	my $ret;
	while ( $buf !~ /DB<\d+>/ ) {
		$ret = $self->{new_sock}->sysread( $buf, 1024, length $buf );
		if ( not defined $ret ) {
			carp $!; # TODO better error handling?
		}

		# _logger("---- ret '$ret'\n$buf\n---");
		if ( not $ret ) {
			last;
		}
	}
	_logger("---- ret $ret\n$buf\n---");
	_logger("_get done");

	$self->{buffer} = $buf;
	return $buf;
}

#######
# Internal Method _logger
#######
sub _logger {
	print "LOG: $_[0]\n" if $ENV{DEBUG_LOGGER};
	return;
}

#######
# Internal Method _parse_dumper
#######
sub _parse_dumper {
	my ($str) = @_;
	return $str;
}

#######
# Internal Method _process_line
#######
# Internal method that receives a reference to a scalar
# containing the data printed by the debugger
# If the output indicates that the debugger terminated return '<TERMINATED>'
# Otherwise it returns   ( $package, $file, $row, $content );
# where
#    $package   is  main::   or   Some::Module::   (the current package)
#    $file      is the full or relative path to the current file
#    $row       is the current row number
#    $content   is the content of the current row
# see 00-internal.t for test cases
sub _process_line {
	my ( $self, $buf ) = @_;

	if ( not defined $buf or not ref $buf or ref $buf ne 'SCALAR' ) {
		carp('_process_line should be called with a reference to a scalar');
	}

	if ( $$buf =~ /Debugged program terminated/ ) {
		return '<TERMINATED>';
	}

	my @parts = split /\n/, $$buf;
	
	my $line = BLANK;
	my $module  = BLANK;
	my $file    = BLANK;
	my $row     = BLANK;
	my $content = BLANK;
	$line = pop @parts;

	#TODO $line is where all CPAN_Testers errors come from
	# try to debug some test reports
	# http://www.nntp.perl.org/group/perl.cpan.testers/2009/12/msg6542852.html
	if ( not defined $line ) {
		croak("Debug::Client: Line is undef. Buffer is $$buf");
	}

	# _logger("Line1: $line");
	my $cont = 0;
	if ($line) {
		if ( $line =~ /^\d+:   \s*  (.*)$/x ) {
			$cont = $1;
			$line = pop @parts;
			# my $next_line = pop @parts;
		# if ( defined $next_line ) {
			# $line = pop @parts;
		# }

			# _logger("Line2: $line");
		}
	}

	$$buf = join "\n", @parts;
	# my ( $module, $file, $row, $content ) = q{ };

	# the last line before
	# main::(t/eg/01-add.pl:8):  my $z = $x + $y;

	if ( $line =~ m{^([\w:]*) 			# module
                  \( ([^\)]*):(\d+) \) 	# (file:row)
                  :\t? 					# :
                  (.*) 					# content
                  }mx
		)
	{
		( $module, $file, $row, $content ) = ( $1, $2, $3, $4 );
	}
	if ( $module eq BLANK || $file eq BLANK || $row eq BLANK ) {

# 		# unless ( defined $module || defined $file || defined $row ) {
		my $current_file = $self->show_line();
		# p $current_file;

		$current_file =~ m/^([\w:]*) \( (.*) : (\d+) .* /mx;

		$module  = $1;
		$file    = $2;
		$row     = $3;
		# p $module;
		# p $file;
		# p $row;
	}
	
	if ($cont) {
		$content = $cont;
	}

	# if ($file) {

# # 		$self->{filename} = $file;

# # 		# print "filename: $self->{filename}\n";
	# }	
	$self->{module}   = $module;
	$self->{filename} = $file;
	$self->{row} = $row;
	return ( $module, $file, $row, $content );
}




#######
# Internal Method _prompt
#######
# It takes one argument which is a reference to a scalar that contains the
# the text sent by the debugger.
# Extracts and prompt that looks like this:   DB<3> $
# puts the number from the prompt in $self->{prompt} and also returns it.
# See 00-internal.t for test cases
sub _prompt {
	my ( $self, $buf ) = @_;

	# _logger("-prompt buf: $$buf");

	if ( not defined $buf or not ref $buf or ref $buf ne 'SCALAR' ) {
		croak('_prompt should be called with a reference to a scalar');
	}

	my $prompt;
	if ( $$buf =~ s/\s*DB<(\d+)>\s*$// ) {
		$prompt = $1;
		_logger("prompt: $prompt");
	}
	chomp($$buf);

	return $self->{prompt} = $prompt;
}

#######
# Internal Method _send
#######
sub _send {
	my ( $self, $input ) = @_;

	#print "Sending '$input'\n";
	print { $self->{new_sock} } "$input\n";

	return 1;
}

#######
# Internal Method _send_get
#######
sub _send_get {
	my ( $self, $input ) = @_;
	$self->_send($input);

	return $self->get;
}

#######
# Internal Method __send_padre
# hidden undocumented
######
sub __send {
	my ( $self, $input ) = @_;
	$self->_send($input);

	my $buf = $self->_get;

	$self->_prompt( \$buf );

	return $buf;
}
#######
# Internal Method __send_np
# hidden undocumented
######
sub __send_np {
	my ( $self, $input ) = @_;
	$self->_send($input);

	# print "input: $input\n";

	my $buf = $self->_get;

	# print "buffer: $buf\n";

	return $buf;
}

1;

__END__

=head1 BUGS AND LIMITATIONS

Debug::Client 0.12 tests are failing, due to changes in perl debugger, 
when using perl5db.pl v1.34
Debug::Client 0.13_01 skips added to failing tests.

 c [line|sub]

Continue, optionally inserting a one-time-only breakpoint at the specified line or subroutine.

 c is now ignoring options [line|sub]

and just performing c on it's own

=head1 INTERNAL METHODS

=head3 _get

=head3 _logger

=head3 _parse_dumper

=head3 _process_line

=head3 _prompt

=head3 _send

=head3 _send_get

=head3 _set_option

=head1 AUTHORS

Gabor Szabo E<lt>gabor@szabgab.comE<gt>

Breno G. de Oliveira E<lt>garu at cpan.orgE<gt>

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

Ahmad M. Zawawi E<lt>ahmad.zawawi@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2008-2011 Gabor Szabo. L<http://szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 WARRANTY

There is no warranty whatsoever.
If you lose data or your hair because of this program,
that's your problem.

=head1 CREDITS and THANKS

Originally started out from the remoteport.pl script from 
Pro Perl Debugging written by Richard Foley.

=head1 See Also

L<GRID::Machine::remotedebugtut>

=cut
