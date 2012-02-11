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

# Converts Perl to HTML using PPI::HTML

use strict;
use File::Slurp ();
use PPI;
use PPI::HTML;
use CSS::Tiny;

# Get the file
my $file = shift @ARGV;
$file    or barf("File '$file' not provided");
-f $file or barf("File '$file' does not exist");

# Determine the output file
my $output = @ARGV ? shift(@ARGV) : $file . '.html';

print "Reading $file...\n";
my $Document = PPI::Document->new( $file )
	or barf("File '$file' could not be loaded as a document");

# Set up some custom CSS properties
my $CSS = CSS::Tiny->new;
$CSS->{body}->{'font-family'} = 'Courier New, Courier, mono';
$CSS->{body}->{'font-size'}   = '10pt';

# Create the PPI::HTML object
my $HTML = PPI::HTML->new(
	line_numbers => 1,
	page         => 1,
	css          => $CSS,
	colors       => {
		# Standard token classes
		pod           => '#008080',
		comment       => '#008080',
		operator      => '#DD7700',
		single        => '#999999',
		double        => '#999999',
		literal       => '#999999',
		interpolate   => '#999999',
		words         => '#999999',
		regex         => '#9900FF',
		match         => '#9900FF',
		substitute    => '#9900FF',
		transliterate => '#9900FF',
		number        => '#990000',
		magic         => '#0099FF',
		cast          => '#339999',

		# Special classes
		pragma        => '#990000',
		keyword       => '#0000FF',
		core          => '#FF0000',
		line_number   => '#666666',
		},
	)
	or barf("Failed to create HTML syntax highlighter");

# Process the file
my $content = $HTML->html( $Document )
	or barf("Failed to generate HTML");
$content =~ s/\t/    /gs;
$content =~ s/<br>//gs;

File::Slurp::write_file( $output, $content );
print "Saved HTML to $output\n";

exit(0);

# Support Functions

sub barf {
	my $msg = shift;
	print $msg . "\n";
	exit(1);
}

__END__
:endofperl
