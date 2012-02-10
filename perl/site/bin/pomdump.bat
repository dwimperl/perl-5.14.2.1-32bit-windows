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
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Pod::POM;
use Getopt::Std;
use File::Basename;

my $program = basename($0);

my %opts;
getopts('h', \%opts);
die usage() if $opts{ h };

my $file = shift || die usage();

my $parser = Pod::POM->new( code => 1 )
    || die "$Pod::POM::ERROR\n";

my $pom = $parser->parse_file($file)
    || die $parser->error(), "\n";

print $pom->dump;


sub usage {
    return <<EOF;
usage: $program file

Parses a Pod file and dumps the parse tree.
EOF
}

=head1 NAME

pomdump - dump the POM parse tree for a POD document

=head1 SYNOPSIS

    pomdump MyFile.pm

=head1 DESCRIPTION

This script uses Pod::POM to parse a Pod document and then invokes the 
dump method on the top level node, resulting in a visualization of the
structure of the POD document (the parse tree).

=head1 AUTHOR

Andrew Ford E<lt>A.Ford@ford-mason.co.ukE<gt>

=head1 VERSION

This is version 0.1 of pomdump.

=head1 COPYRIGHT

Copyright (C) 2009 Andrew Ford.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

For further information please see L<Pod::POM>.

__END__
:endofperl
