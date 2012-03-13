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
use strict;
use Clipboard;

my $orig = Clipboard->paste;

my $tmpfilename = "/tmp/clipedit$$";
open my $tmpfile, ">$tmpfilename" or die "Failure to open $tmpfilename: $!";
print $tmpfile $orig;
close $tmpfile;

my $ed = $ENV{VISUAL} || $ENV{EDITOR} || 'vim';
system($ed, $tmpfilename);

open $tmpfile, $tmpfilename or die "Failure to open $tmpfilename: $!";
my $edited = join '', <$tmpfile>;

my $current = Clipboard->paste;

if ($current ne $orig) {
    local $| = 1;
    boldprint("1) When you started, the Clipboard contained:\n");
    print $orig;
    boldprint("\n2) ...but now the Clipboard contains:\n");
    print $current;
    boldprint("\n3) and you edited to this:\n");
    print $edited;
    boldprint("\nWhich would you like to use (1, 2, or the default, 3)? ");
    my %actions = (
        1 => $orig,
        2 => $current,
        3 => $edited,
    );
    my $answer;
    while (1) {
        $answer = <STDIN>;
        chomp $answer;
        $answer = 3 if $answer eq '';
        last if exists $actions{$answer};
        my @puzzles = qw(hrm what huh uhh who because sneevle);
        boldprint(ucfirst($puzzles[int rand $#puzzles]) . "? ");
    }
    $edited = $actions{$answer};
}
Clipboard->copy($edited);
print Clipboard->paste;
boldprint("\n...is now in the Clipboard\n");

unlink($tmpfilename) or die "Couldn't remove $tmpfilename: $!";

sub boldprint {
    # If you are in a situation where this output is annoying, such as in a
    # DOS console without ANSI parsing, please send a patch.  For now, I'll
    # just do the simplest thing and print it every time:
    printf "\e[033m%s\e[0m", shift;
}

=head1 NAME

clipedit - Edit clipboard contents in one swoop.

=head1 MOTIVATION

Eliminating the "Open editor, edit stuff, copy back to the clipboard" shuffle.

=head1 NOTE

If for some reason the clipboard contents changes during the edit session, you
will be prompted to choose between 1) the original Clipboard contents, 2) the
new Clipboard contents, and 3) the result of your edits (which is the default
if you just hit "Enter").

=head1 CONFIGURATION

If you don't want the script to use C<vim> to edit, set either the
environment variable C<$VISUAL> or C<$EDITOR>.

=head1 AUTHOR

Ryan King <rking@panoptic.com>

=head1 COPYRIGHT

Copyright (c) 2010.  Ryan King.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

__END__
:endofperl
