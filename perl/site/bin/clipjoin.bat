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
use Clipboard;
use strict;
my $data = join '', Clipboard->paste;
$data =~ s/\s+\|\s+//gm;
$data =~ s/^\+//gm;
$data =~ s/\n//gms;
$data =~ s/\s{2,}/ /g;
Clipboard->copy($data);
print Clipboard->paste, "\n...is now in the Clipboard\n"
    unless $ARGV[0] eq '-q';

=head1 NAME

clipjoin - Remove superfluous spaces from the clipboard.

=head1 MOTIVATION

Often you'll copy some stuff, like this:

  <ingy> hey rking, you should use YBFOD: http://search.cpan
    | .org/~ingy/Acme-YBFOD-0.11/

Getting that URL to a browser is tedious.

Another IRC example is longer quotes:

  <strunk> Objective consideration of contemporary phenomena compels the
      conclusion that success or failure in competitive activities
      exhibits no tendency to be commensurate with enate capacity but
      that a considerable element of the unpredictable must invariably
      be taken into account. I returned, and saw under the sun, that the
      race is not to the swift, nor the battle to the strong, neither
      yet bread to the wise, nor yet riches to men of understanding, nor
      yet favour to men of skill, but time and chance happeneth to them all.

If you wanted to quote that to someone, you'd have \n's and "   "'s
everywhere, unless you ran "clipjoin" first.

An example from mutt:

,-------------------------------------------.
|  xterm                                (X) |
+-------------------------------------------+
| http://www.thisisalink.com/that/wrapped/ar|
|+ound/a/line/and/its/a/pain/without/the/joi|
|+inclip/script                             |
`-------------------------------------------'

Becomes:
http://www.thisisalink.com/that/wrapped/around/a/line/and/its/a/pain/without/the/clipjoin/script

=head1 AUTHOR

Ryan King <rking@panoptic.com>

=head1 COPYRIGHT

Copyright (c) 2010.  Ryan King.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

__END__
:endofperl
