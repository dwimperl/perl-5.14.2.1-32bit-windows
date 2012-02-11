package strictures;

use strict;
use warnings FATAL => 'all';

our $VERSION = '1.002002'; # 1.2.2

sub VERSION {
  for ($_[1]) {
    last unless defined && !ref && int != 1;
    die "Major version specified as $_ - this is strictures version 1";
  }
  # disable this since Foo->VERSION(undef) correctly returns the version
  # and that can happen either if our caller passes undef explicitly or
  # because the for above autovivified $_[1] - I could make it stop but
  # it's pointless since we don't want to blow up if the caller does
  # something valid either.
  no warnings 'uninitialized';
  shift->SUPER::VERSION(@_);
}

sub import {
  strict->import;
  warnings->import(FATAL => 'all');
  my $extra_tests = do {
    if (exists $ENV{PERL_STRICTURES_EXTRA}) {
      $ENV{PERL_STRICTURES_EXTRA}
    } else {
      !!($0 =~ /^x?t\/.*(?:load|compile|coverage|use_ok).*\.t$/
         and (-e '.git' or -e '.svn'))
    }
  };
  if ($extra_tests) {
    if (eval {
          require indirect;
          require multidimensional;
          require bareword::filehandles;
          1
        }) {
      indirect->unimport(':fatal');
      multidimensional->unimport;
      bareword::filehandles->unimport;
    } else {
      die "strictures.pm extra testing active but couldn't load modules.
Extra testing is auto-enabled in checkouts only, so if you're the author
of a strictures using module you need to run:

  cpan indirect multidimensional bareword::filehandles

but these modules are not required by your users.

Error loading modules was: $@";
    }
  }
}

1;

__END__
=head1 NAME

strictures - turn on strict and make all warnings fatal

=head1 SYNOPSIS

  use strictures 1;

is equivalent to

  use strict;
  use warnings FATAL => 'all';

except when called from a file where $0 matches:

  /^x?t\/.*(?:load|compile|coverage|use_ok).*\.t$/

and when either '.git' or '.svn' is present in the current directory (with
the intention of only forcing extra tests on the author side) - or when the
PERL_STRICTURES_EXTRA environment variable is set, in which case

  use strictures 1;

is equivalent to

  use strict;
  use warnings FATAL => 'all';
  no indirect 'fatal';
  no multidimensional;
  no bareword::filehandles;

Note that _EXTRA may at some point add even more tests, with only a minor
version increase, but any changes to the effect of 'use strictures' in
normal mode will involve a major version bump.

Be aware: THIS MEANS THE EXTRA TEST MODULES ARE REQUIRED FOR AUTHORS OF
STRICTURES USING CODE - but not by end users thereof.

=head1 DESCRIPTION

I've been writing the equivalent of this module at the top of my code for
about a year now. I figured it was time to make it shorter.

Things like the importer in 'use Moose' don't help me because they turn
warnings on but don't make them fatal - which from my point of view is
useless because I want an exception to tell me my code isn't warnings clean.

Any time I see a warning from my code, that indicates a mistake.

Any time my code encounters a mistake, I want a crash - not spew to STDERR
and then unknown (and probably undesired) subsequent behaviour.

I also want to ensure that obvious coding mistakes, like indirect object
syntax (and not so obvious mistakes that cause things to accidentally compile
as such) get caught, but not at the cost of an XS dependency and not at the
cost of blowing things up on another machine.

Therefore, strictures turns on indirect checking only when it thinks it's
running in a compilation (or pod coverage) test - though if this causes
undesired behaviour this can be overridden by setting the
PERL_STRICTURES_EXTRA environment variable.

If additional useful author side checks come to mind, I'll add them to the
_EXTRA code path only - this will result in a minor version increase (i.e.
1.000000 to 1.001000 (1.1.0) or similar). Any fixes only to the mechanism of
this code will result in a subversion increas (i.e. 1.000000 to 1.000001
(1.0.1)).

If the behaviour of 'use strictures' in normal mode changes in any way, that
will constitute a major version increase - and the code already checks
when its version is tested to ensure that

  use strictures 1;

will continue to only introduce the current set of strictures even if 2.0 is
installed.

=head1 METHODS

=head2 import

This method does the setup work described above in L</DESCRIPTION>

=head2 VERSION

This method traps the strictures->VERSION(1) call produced by a use line
with a version number on it and does the version check.

=head1 COMMUNITY AND SUPPORT

=head2 IRC channel

irc.perl.org #toolchain

(or bug 'mst' in query on there or freenode)

=head2 Git repository

Gitweb is on http://git.shadowcat.co.uk/ and the clone URL is:

  git clone git://git.shadowcat.co.uk/p5sagit/strictures.git

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None required yet. Maybe this module is perfect (hahahahaha ...).

=head1 COPYRIGHT

Copyright (c) 2010 the strictures L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
