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
require 5;            # Time-stamp: "2001-10-27 00:08:46 MDT"
use strict;
use Pod::Spell;
if(@ARGV) {  # iterate over files, sending to STDOUT
  foreach my $x (@ARGV) {
    Pod::Spell->new->parse_from_file($x, '-');
  }
} else {     # take from STDIN, send to STDOUT
  Pod::Spell->new->parse_from_filehandle();
}

__END__

__END__
:endofperl
