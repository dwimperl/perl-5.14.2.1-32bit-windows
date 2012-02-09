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

use warnings;
use strict;

use Getopt::Long;
use HTML::Lint;
use HTML::Lint::HTML4;

my $help;
my $context;

my $structure = 1;
my $helper    = 1;
my $fluff     = 1;

GetOptions(
    'help'       => \$help,
    'context:i'  => \$context,
    'only'       => sub { $structure = $helper = $fluff = 0; },
    'structure!' => \$structure,
    'helper!'    => \$helper,
    'fluff!'     => \$fluff,
) or $help = 1;

if ( !@ARGV || $help ) {
    print "weblint v$HTML::Lint::VERSION\n";
    print <DATA>;
    exit 1;
}

my @types;
push( @types, HTML::Lint::Error::STRUCTURE ) if $structure;
push( @types, HTML::Lint::Error::HELPER )    if $helper;
push( @types, HTML::Lint::Error::FLUFF )     if $fluff;

my $lint = HTML::Lint->new;
$lint->only_types( @types ) if @types;
for my $url ( @ARGV ) {
    my @lines;
    $lint->newfile( $url );
    if ( $url =~ /^https?:/ ) {
        eval { require LWP::Simple };
        if ( $@ ) {
            warn q{Can't retrieve URLs without LWP::Simple installed};
            next;
        }

        my $content = LWP::Simple::get( $url );
        if ( $content ) {
            @lines = split( /\n/, $content );
            $_ = "$_\n" for @lines;
        }
        else {
            warn "Unable to fetch $url\n";
            next;
        }
    }
    else {
        open( my $fh, '<', $url ) or die "Can't open $url: $!";
        @lines = <$fh>;
        close $fh;
    }
    $lint->parse( $_ ) for @lines;
    $lint->eof();
    for my $error ( $lint->errors() ) {
        print $error->as_string(), "\n";
        if ( defined $context ) {
            $context += 0;
            my $lineno = $error->line - 1;

            my $start = $lineno-$context;
            $start = 0 if $start < 0;

            my $end = $lineno+$context;
            $end = $#lines if $end > $#lines;

            print "    $_\n" for @lines[$start..$end];
            print "\n";
        }
    }
    $lint->clear_errors();
} # for files

__END__
Usage: weblint [filename or url]... (filename - reads STDIN)
    --help          This message
    --context[=n]   Show the offending line (and n surrounding lines)

    Error types: (default: all on)
    --[no]structure Structural issues, like unclosed tag pairs
    --[no]helper    Helper issues, like missing HEIGHT & WIDTH
    --[no]fluff     Fluff that can be removed, like bad tag attributes
    --only          Turns off all other error types, as in --only --fluff


__END__
:endofperl
