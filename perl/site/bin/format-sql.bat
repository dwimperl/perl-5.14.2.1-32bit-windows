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
#!/usr/bin/env perl
#line 15

use SQL::Abstract::Tree;
use Getopt::Long::Descriptive;

my ($opt, $usage) = describe_options(
  'format-sql %o',
  [ 'profile|p=s',   "the profile to use", { default => 'console' } ],
  [ 'help',       "print usage message and exit" ],
);

  print($usage->text), exit if $opt->help;

my $sqlat = SQL::Abstract::Tree->new({ profile => $opt->profile });

print $sqlat->format($_) . "\n" while <>;

__END__
:endofperl
