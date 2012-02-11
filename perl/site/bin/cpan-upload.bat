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
#!perl
#line 15
use strict;
use warnings;
package
  cpan_upload;
# ABSTRACT: upload a distribution to the CPAN

use CPAN::Uploader;
use Getopt::Long::Descriptive 0.084;


my %arg;

my $from_file = CPAN::Uploader->read_config_file;

# This nonsensical hack is to cope with Module::Install wanting to call
# cpan-upload -verbose; it should be made to use CPAN::Uploader instead.
$ARGV[0] = '--verbose' if @ARGV == 2 and $ARGV[0] eq '-verbose';

# Process arguments
my ($opt, $usage) = describe_options(
	"usage: %c [options] file-to-upload",

  [ "verbose|v" => "enable verbose logging" ],
  [ "help|h"    => "display this help message" ],
  [ "dry-run"   => "do not actually upload anything" ], 
  [],
  [ "user|u=s"      => "your PAUSE username" ],
  [ "password|p=s"  => "the password to your PAUSE account" ],
  [ "directory|d=s" => "a dir in your CPAN space in which to put the file" ],
  [ "http-proxy=s"  => "URL of the http proxy to use in uploading" ],
);

if ($opt->help) {
  print $usage->text;
  exit;
}

die "Please provide a file name.\n" . $usage unless my $file = $ARGV[0];

$arg{user} = $opt->_specified('user') ? $opt->user : $from_file->{user};

die "Please provide a value for --user\n" unless defined $arg{user};

$arg{user} = uc $arg{user};

$arg{password} = $opt->password if $opt->_specified('password');

if (
  ! $arg{password}
  and defined $from_file->{user}
  and ($arg{user} eq uc $from_file->{user})
) {
  $arg{password} = $from_file->{password};
}

$arg{debug}  = 1 if $opt->verbose;
$arg{subdir} = $opt->directory if defined $opt->directory;

$arg{ $_ } = $opt->$_ for grep { defined $opt->$_ } qw(dry_run http_proxy);

if (! $arg{password}) {
  require Term::ReadKey;
  local $| = 1;
  print "PAUSE Password: ";
  Term::ReadKey::ReadMode('noecho');
  chop($arg{password} = <STDIN>);
  Term::ReadKey::ReadMode('restore');
  print "\n";
}

CPAN::Uploader->upload_file(
  $file,
  \%arg,
);

__END__
=pod

=head1 NAME

cpan_upload - upload a distribution to the CPAN

=head1 VERSION

version 0.103000

=head1 USAGE

  usage: cpan-upload [options] file-to-upload
    -v --verbose       enable verbose logging
    -h --help          display this help message
    --dry-run          do not actually upload anything
                     
    -u --user          your PAUSE username
    -p --password      the password to your PAUSE account
    -d --directory     a dir in your CPAN space in which to put the file
    --http-proxy       URL of the http proxy to use in uploading

=head1 CONFIGURATION

If you have a C<.pause> file in your home directory, it will be checked for a
username and password.  It should look like this:

  user EXAMPLE
  password your-secret-password

=head1 SEE ALSO

L<CPAN::Uploader>

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
:endofperl
