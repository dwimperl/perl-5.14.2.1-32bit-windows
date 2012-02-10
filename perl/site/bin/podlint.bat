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

use Pod::POM;
use Getopt::Std;
use File::Basename;

my $program = basename($0);

my %opts;
getopts('fh', \%opts);
die usage() if $opts{ h };

my $file = shift || die usage();

my $parser = Pod::POM->new( warn => 1, code => 1 )
    || die "$Pod::POM::ERROR\n";

my $pom = $parser->parse_file($file)
    || die $parser->error(), "\n";

print $pom if $opts{ f };


sub usage {
    return <<EOF;
usage: $program [-f] file

Checks Pod file for well-formedness, printing warnings to STDERR.  
The -f option can be set to fix problems (where possible), printing 
the modified output to STDOUT.
EOF
}

=head1 NAME

podlint - check POD for correctness using Pod::POM

=head1 SYNOPSIS

    podlint MyFile.pm

=head1 DESCRIPTION

This script uses Pod::POM to parse a Pod document with full 
warnings enabled, effectively acting as a syntax and structure
checker.

The -f option can be specified to have the parsed Pod Object Model
printed to STDOUT with any markup errors fixed.  Note there are some
critical parse errors that can't be handled and fixed by the parser
and in this case the script will terminate reporting the error.

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version 0.2 of podlint.

=head1 COPYRIGHT

Copyright (C) 2000, 2001 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

For further information please see L<Pod::POM>.

__END__
:endofperl
