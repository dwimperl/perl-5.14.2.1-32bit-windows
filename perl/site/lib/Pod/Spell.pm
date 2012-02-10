
require 5;
package Pod::Spell;    # Time-stamp: "2001-10-27 00:05:01 MDT"
use strict;
use vars qw(@ISA $VERSION);
$VERSION = '1.01';
use Pod::Parser ();
@ISA = ('Pod::Parser');

use constant MAXWORDLENGTH => 50; # max length of a word

BEGIN { *DEBUG = sub () {0} unless defined &DEBUG }
use Pod::Wordlist ();
use Pod::Escapes ('e2char');
use Text::Wrap ('wrap');
 # We don't need a very new version of Text::Wrap, altho they are nicer.
$Text::Wrap::huge = 'overflow';

use integer;
use locale;    # so our uc/lc works right
use Carp;

#==========================================================================
#
#  Override some methods
#

sub new {
  my $x = shift;
  my $new = $x->SUPER::new(@_);
  $new->{'spell_stopwords'} = { };
  @{ $new->{'spell_stopwords'} }{ keys %Pod::Wordlist::Wordlist } = ();
  $new->{'region'} = [];
  return $new;
}

sub verbatim { return ''; } # totally ignore verbatim sections

#----------------------------------------------------------------------

sub _get_stopwords_from {
  my $stopwords = $_[0]{'spell_stopwords'};

  my $word;
  while($_[1] =~ m<(\S+)>g) {
    $word = $1;
    if($word =~ m/^!(.+)/s) {  # "!word" deletes from the stopword list
      delete $stopwords->{$1};
      DEBUG and print "Unlearning stopword $1\n";
    } else {
      $stopwords->{$1} = 1;
      DEBUG and print "Learning stopword $1\n";
    }
  }
  return;

}

#----------------------------------------------------------------------

sub textblock {
  my($self, $paragraph) = @_;
  if(@{ $self->{'region'} }) {
    my $last = $self->{'region'}[-1];
    if($last eq 'stopwords') {
      $self->_get_stopwords_from( $paragraph );
      return;
    } elsif($last eq ':stopwords') {
      $self->_get_stopwords_from( $self->interpolate($paragraph) );
       # I guess that'd work.
      return;
    } elsif($last !~ m/^:/s) {
      DEBUG and printf "Ignoring a textblock because inside a %s region.\n",
        $self->{'region'}[-1];
      return;
    }
     # else fall thru, as with a :footnote region or something...
  }
  $self->_treat_words( $self->interpolate($paragraph) );
  return;
}

sub command {
  my $self = shift;
  my $command = shift;
  return if $command eq 'pod';

  if($command eq 'begin') {
    my $region_name;
    #print "BEGIN <$_[0]>\n";
    if(shift(@_) =~ m/^\s*(\S+)/s) {
      $region_name = $1;
    } else {
      $region_name = 'WHATNAME';
    }
    DEBUG and print "~~~~ Beginning region \"$region_name\" ~~~~\n";
    push @{ $self->{'region'} }, $region_name;
    
  } elsif($command eq 'end') {
    pop @{ $self->{'region'} }; # doesn't bother to check

  } elsif($command eq 'for') {
    if($_[0] =~ s/^\s*(\:?)stopwords\s*(.*)//s) {
      my $para = $2;
      $para = $self->interpolate($para) if $1;
      DEBUG > 1 and print "Stopword para: <$2>\n";
      $self->_get_stopwords_from( $para );
    }
  } elsif(@{ $self->{'region'} }) {  # TODO: accept POD formatting
    # ignore
  } elsif(
    $command eq 'head1' or $command eq 'head2' or
    $command eq 'head2' or $command eq 'head3' or
    $command eq 'item'
  ) {
    my $out_fh = $self->output_handle();
    print $out_fh "\n";
    $self->_treat_words( $self->interpolate(shift) );
    #print $out_fh "\n";
  } else {
    # no-op
  }
  return;
}

#--------------------------------------------------------------------------

sub interior_sequence {
  my $self = shift;
  my $command = shift;

  return '' if $command eq 'X' or $command eq 'Z';

  local $_ = shift;

  # Expand escapes into the actual character now, carping if invalid.
  if ($command eq 'E') {
    my $it = e2char($_);
    if(defined $it) {
      return $it;
    } else {
      carp "Unknown escape: E<$_>";
      return "E<$_>";
    }
  }

  # For all the other sequences, empty content produces no output.
  return if $_ eq '';

  if ($command eq 'B' or $command eq 'I' or $command eq 'S') {
    $_;
  } elsif ($command eq 'C' or $command eq 'F') {
    # don't lose word-boundaries
    my $out = '';
    $out .= ' ' if s/^\s+//s;
    my $append;
    $append = 1 if s/\s+$//s;
    $out .= '_' if length $_;
     # which, if joined to another word, will set off the Perl-token alarm
    $out .= ' ' if $append;
    $out;
  } elsif ($command eq 'L') {
    return $1 if m/^([^|]+)\|/s;
    '';
  } else {
    carp "Unknown sequence $command<$_>"
  }
}

#==========================================================================
# The guts:

sub _treat_words {
  my $p = shift;
  # Count the things in $_[0]
  DEBUG > 1 and print "Content: <", $_[0], ">\n";

  my $stopwords = $p->{'spell_stopwords'};
  my $word;
  $_[0] =~ tr/\xA0\xAD/ /d;
    # i.e., normalize non-breaking spaces, and delete soft-hyphens
  
  my $out = '';
  
  my($leading, $trailing);
  while($_[0] =~ m<(\S+)>g) {
    # Trim normal English punctuation, if leading or trailing.
    next if length $1 > MAXWORDLENGTH;
    $word = $1;
    if( $word =~ s/^([\`\"\'\(\[])//s )
     { $leading = $1 } else { $leading = '' }
    
    if( $word =~ s/([\)\]\'\"\.\:\;\,\?\!]+)$//s )
     { $trailing = $1 } else { $trailing = '' }
    
    if($word =~ m/^[\&\%\$\@\:\<\*\\\_]/s
           # if it looks like it starts with a sigil, etc.
       or $word =~ m/[\%\^\&\#\$\@\_\<\>\(\)\[\]\{\}\\\*\:\+\/\=\|\`\~]/
            # or contains anything strange
    ) {
      DEBUG and print "rejecting {$word}\n" unless $word eq '_';
      next;
    } else {
      if(exists $stopwords->{$word} or exists $stopwords->{lc $word}) {
        DEBUG and print " [Rejecting \"$word\" as a stopword]\n";
      } else {
        $out .= "$leading$word$trailing ";
      }
    }
  }

  if(length $out) {
    my $out_fh = $p->output_handle();
    print $out_fh wrap('','',$out), "\n\n";
  }

  return;
}

#--------------------------------------------------------------------------

1;
__END__

=head1 NAME

Pod::Spell -- a formatter for spellchecking Pod

=head1 SYNOPSIS

  % podspell Thing.pm | ispell
 or if you don't have a podspell:
  % perl -MPod::Spell -e "Pod::Spell->new->parse_from_file(shift)" Thing.pm |spell |fmt

 or:
  % perl -MPod::Spell -e "Pod::Spell->new->parse_from_filehandle"
  ...which takes POD on STDIN and sends formatted text to STDOUT

...or instead of piping to spell or ispell, use C<E<gt>temp.txt>, and open
F<temp.txt> in your word processor for spell-checking.


=head1 DESCRIPTION

Pod::Spell is a Pod formatter whose output is good for
spellchecking.  Pod::Spell rather like L<Pod::Text|Pod::Text>, except that
it doesn't put much effort into actual formatting, and it suppresses things
that look like Perl symbols or Perl jargon (so that your spellchecking
program won't complain about mystery words like "C<$thing>" 
or "C<Foo::Bar>" or "hashref").

This class provides no new public methods.  All methods of interest are
inherited from L<Pod::Parser|Pod::Parser> (which see).  The especially
interesting ones are C<parse_from_filehandle> (which without arguments
takes from STDIN and sends to STDOUT) and C<parse_from_file>.  But you
can probably just make do with the examples in the synopsis though.

This class works by filtering out words that look like Perl or any
form of computerese (like "C<$thing>" or "C<NE<gt>7>" or
"C<@{$foo}{'bar','baz'}>", anything in CE<lt>...E<gt> or FE<lt>...E<gt>
codes, anything in verbatim paragraphs (codeblocks), and anything
in the stopword list.  The default stopword list for a document starts
out from the stopword list defined by L<Pod::Wordlist|Pod::Wordlist>,
and can be supplemented (on a per-document basis) by having 
C<"=for stopwords"> / C<"=for :stopwords"> region(s) in a document.


=head1 ADDING STOPWORDS

You can add stopwords on a per-document basis with
C<"=for stopwords"> / C<"=for :stopwords"> regions, like so:

  =for stopwords  plok Pringe zorch   snik !qux
  foo bar baz quux quuux 

This adds every word in that paragraph after "stopwords" to the
stopword list, effective for the rest of the document.  In such a
list, words are whitespace-separated.  (The amount of whitespace
doesn't matter, as long as there's no blank lines in the middle
of the paragraph.)  Words beginning with "!" are
I<deleted> from the stopword list -- so "!qux" deletes "qux" from the
stopword list, if it was in there in the first place.  Note that if
a stopword is all-lowercase, then it means that it's okay in I<any>
case; but if the word has any capital letters, then it means that
it's okay I<only> with I<that> case.  So a wordlist entry of "perl"
would permit "perl", "Perl", and (less interestingly) "PERL", "pERL",
"PerL", et cetera.  However, a wordlist entry of "Perl" catches
only "Perl", not "perl".  So if you wanted to make sure you said
only "Perl", never "perl", you could add this to the top of your
document:

  =for stopwords !perl Perl

Then all instances of the word "Perl" would be weeded out of the
Pod::Spell-formatted version of your document, but any instances of
the word "perl" would be left in (unless they were in a CE<lt>...> or 
FE<lt>...> style).

You can have several "=for stopwords" regions in your document.  You
can even express them like so:

  =begin stopwords

  plok Pringe zorch

  snik !qux

  foo bar
  baz quux quuux 

  =end stopwords

If you want to use EE<lt>...> sequences in a "stopwords" region, you
have to use ":stopwords", as here:

  =for :stopwords
  virtE<ugrave>

...meaning that you're adding a stopword of "virtE<ugrave>".  If
you left the ":" out, that'd mean you were adding a stopword of
"virtEE<lt>ugrave>" (with a literal E, a literal <, etc), which
will have no effect, since  any occurrences of virtEE<lt>ugrave>
don't look like a normal human-language word anyway, and so would
be screened out before the stopword list is consulted anyway.


=head1 USING Pod::Spell

My personal advice:

=over

=item *

Write your documentation in Pod.  Pod is described in
L<perlpod|perlpod>.  And L<perlmodstyle|perlmodstyle> has some
advice on content.  This is the stage where you want to make sure
you say everything you should, have good and working examples,
and have coherent grammar.

=item *

Run it through podchecker.  This will report all sorts of problems with
your Pod; you may choose to ignore some of these problems.  Some, like
"*** WARNING: Unknown entity EE<lt>qacute>...", you should pay attention
to.

=item *

Once podchecker errors have been tended to, spellcheck the pod by
running it through podspell / Pod::Spell.  For any misspellings that are
reported in the Pod::Spell-formatted text, fix them in the
original.  Repeat until there's no complaints.

=item *

Run it through podchecker again just for good measure.

=back


=head1 SEE ALSO

L<Pod::Wordlist|Pod::Wordlist>

L<Pod::Parser|Pod::Parser>

L<podchecker|podchecker> also known as L<Pod::Checker|Pod::Checker>

L<perlpod|perlpod>, L<perlpodspec|perlpodspec>



=head1 HINT

If you feed output of Pod::Spell into your word processor and run a
spell-check, make sure you're I<not> also running a grammar-check -- because
Pod::Spell drops words that it thinks are Perl symbols, jargon, or
stopwords, this means you'll have ungrammatical sentences, what with
words being missing and all.  And you don't need a grammar checker
to tell you that.



=head1 COPYRIGHT AND DISCLAIMER

Copyright (c) 2001 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

The programs and documentation in this dist are distributed in
the hope that they will be useful, but without any warranty; without
even the implied warranty of merchantability or fitness for a
particular purpose.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut


