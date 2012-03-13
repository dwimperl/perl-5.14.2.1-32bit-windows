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
use Clipboard;
my $browser = $ENV{BROWSER} || 'chromium-browser "%s"';
$browser .= ' %s' unless $browser =~ /%s/;
my $query = Clipboard->paste;
$query =~ s/['"]/\\$&/;
system(sprintf $browser, $query);

=head1 NAME

clipbrowse - Load a URL from the clipboard into your browser.

=head1 USAGE

# ...copy something
# (You might want to do a `clipjoin` if the URL text is messy)
$ clipbrowse

Remember that many browsers will usefully load things that don't look like
URL's. For example Firefox does a Google "I'm feeling lucky" with non-URLs.
This means you can have any text in your clipboard and `clipbrowse`.

=head1 MOTIVATION

It saves a couple of seconds every time you run it.  Chrome and Firefox, for
examples, automatically create a new tab and loads the page when you invoke it
from the command line.  Already we've saved a Ctrl+T and a Shift+Insert.  When
you consider the parallelizing (that your browser will be actively loading the
page while you're Alt+Tabbing to it), you've squeaked out a little more.

Maybe I'm just a freak, but I like shaving out wasted time like that.

=head1 CONFIGURATION

The environment variable C<$BROWSER> will override the default launching
command.  If you have a %s in the line, it will be replaced with the url.  if
not, the url will be appended at the end.

The default is `chromium-browser "%s"` (Debian's Google Chrome)
If you still use Firefox, consider: `firefox -remote "openURL(%s,new-tab)"'`.

=head1 AUTHOR

Ryan King <rking@panoptic.com> 
=head1 COPYRIGHT

Copyright (c) 2010.  Ryan King.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

__END__
:endofperl
