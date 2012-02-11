@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!/usr/bin/perl -w
#line 15
use strict;

$| = 1;

unless (@ARGV >= 1) {
	print STDERR qq(Usage:
$0 [filename] query
				
	If no filename is given, supply XML on STDIN.
);
	exit;
}

use XML::XPath;

my $xpath;

my $pipeline;

if ($ARGV[0] eq '-p') {
	# pipeline mode
	$pipeline = 1;
	shift @ARGV;
}
if (@ARGV >= 2) {
	$xpath = XML::XPath->new(filename => shift(@ARGV));
}
else {
	$xpath = XML::XPath->new(ioref => \*STDIN);
}

my $nodes = $xpath->find(shift @ARGV);

unless ($nodes->isa('XML::XPath::NodeSet')) {
NOTNODES:
	print STDERR "Query didn't return a nodeset. Value: ";
	print $nodes->value, "\n";
	exit;
}

if ($pipeline) {
	$nodes = find_more($nodes);
	goto NOTNODES unless $nodes->isa('XML::XPath::NodeSet');
}

if ($nodes->size) {
	print STDERR "Found ", $nodes->size, " nodes:\n";
	foreach my $node ($nodes->get_nodelist) {
		print STDERR "-- NODE --\n";
		print $node->toString;
	}
}
else {
	print STDERR "No nodes found";
}

print STDERR "\n";

exit;

sub find_more {
	my ($nodes) = @_;
	if (!@ARGV) {
		return $nodes;
	}
	
	my $newnodes = XML::XPath::NodeSet->new;
	
	my $find = shift @ARGV;
	
	foreach my $node ($nodes->get_nodelist) {
		my $new = $xpath->find($find, $node);
		if ($new->isa('XML::XPath::NodeSet')) {
			$newnodes->append($new);
		}
		else {
			warn "Not a nodeset: ", $new->value, "\n";
		}
	}
	
	return find_more($newnodes);
}

__END__
:endofperl
