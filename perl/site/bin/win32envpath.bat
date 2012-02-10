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
#!/usr/bin/perl
#line 15

use 5.008;
use strict;
use warnings;
use Params::Util qw{
	_IDENTIFIER
	_INSTANCE
};
use Win32::Env::Path ();

use vars qw{$VERSION};
BEGIN {
	$|       = 1;
	$VERSION = '0.03';
}

exit( main(@ARGV) );





#####################################################################
# Main Functions

sub main {
	my $cmd = shift @_;
	return usage(@_)       unless defined $cmd;
	return clean(@_)       if $cmd eq 'clean';
	return add(@_)         if $cmd eq 'add';
	return add_push(@_)    if $cmd eq 'push';
	return add_unshift(@_) if $cmd eq 'unshift';
	return remove(@_)      if $cmd eq 'remove';
	return error("Unknown command '$cmd'");
}

sub usage {
	print "\n";
	print "win32envpath $VERSION - Copright 2008 Adam Kennedy\n";
	print "Usage:\n";
	print "  win32envpath PATH clean\n";
	print "  win32envpath PATH add\n";
	print "\n";
	return 0;
}

sub clean {
	my $path = path(shift);
	unless ( $path->clean ) {
		my $name = $path->name;
		error("Failed to clean the '$name' path");
	}
	return 0;
}

sub add {
	my $path = path(shift);
	my $name = $path->name;
	my $dir  = shift;
	unless ( defined $dir and -d $dir ) {
		error("Missing or invalid directory to add to '$name'");
	}
	unless ( $path->add($name) ) {
		error("Failed to push directory onto '$name'");
	}
	return 0;
}

sub add_push {
	my $path = path(shift);
	my $name = $path->name;
	my $dir  = shift;
	unless ( defined $dir and -d $dir ) {
		error("Missing or invalid directory to add to '$name'");
	}
	unless ( $path->push($name) ) {
		error("Failed to push directory onto '$name'");
	}
	return 0;
}

sub add_unshift {
	my $path = path(shift);
	my $name = $path->name;
	my $dir  = shift;
	unless ( defined $dir and -d $dir ) {
		error("Missing or invalid directory to add to '$name'");
	}
	unless ( $path->unshift($name) ) {
		error("Failed to push directory onto '$name'");
	}
	return 0;
}

sub remove {
	my $path = path(shift);
	my $name = $path->name;
	my $dir  = shift;
	unless ( defined $dir and -d $dir ) {
		error("Missing or invalid directory to add to '$name'");
	}
	unless ( $path->remove($dir) ) {
		error("Failed to push directory onto '$name'");
	}
	return 0;
}

sub error {
	my $msg = shift;
	chomp $msg;
	print "\n";
	print "  $msg\n";
	print "\n";
	return 255;
}

sub path {
	my $path = shift;
	unless ( _IDENTIFIER($path) ) {
		error("Missing or invalid path name");
	}
	my $rv = Win32::Env::Path->new(
		name     => $path,
		autosave => 1,
	);
	unless ( _INSTANCE($rv, 'Win32::Env::Path') ) {
		error("Failed to create Win32::Env::Path for path '$path'");
	}
	return $rv;
}

__END__
:endofperl
