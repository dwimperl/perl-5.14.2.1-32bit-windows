package Lingua::EN::Inflect::Phrase;

use strict;
use warnings;
use Exporter 'import';
use Lingua::EN::Inflect::Number;
use Lingua::EN::Tagger;

=head1 NAME

Lingua::EN::Inflect::Phrase - Inflect short English Phrases

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

  use Lingua::EN::Inflect::Phrase;
  use Test::More tests => 2;

  my $plural   = Lingua::EN::Inflect::Phrase::to_PL('green egg and ham');

  is $plural, 'green eggs and ham';

  my $singular = Lingua::EN::Inflect::Phrase::to_S('green eggs and ham');

  is $singular, 'green egg and ham';

=head1 DESCRIPTION

Attempts to pluralize or singularize short English phrases.

If it doesn't work, please email or submit to RT the example you tried, and
I'll try to fix it.

=head1 OPTIONAL EXPORTS

L</to_PL>, L</to_S>

=cut

our @EXPORT_OK = qw/to_PL to_S/;

=head1 SUBROUTINES

=cut

my $NOUN         = qr{(\S+)/NNS?\b};
my $MAYBE_NOUN   = qr{(\S+)/(?:NNS?|CD|JJ)\b};
my $NOUN_OR_VERB = qr{(\S+)/(?:NNS?|CD|JJ|VB[A-Z]?)\b};

my $tagger;

sub _inflect_noun {
  my ($noun, $is_plural, $want_plural, $inflect_method) = @_;
  my $want_singular = not $want_plural;

  if (($want_plural && (not $is_plural)) || ($want_singular && $is_plural)) {
    return $noun->$inflect_method;
  }

  return undef;
}

sub _inflect {
  my ($phrase, $want_plural, $method) = @_;
  my $want_singular = not $want_plural;

# 'a' inflects to 'some', special-case it here
  if ($phrase eq 'a') {
    return $want_singular ? $phrase : 'as';
  }

# Do not tag initial number, if any, unless it's "1" which is handled
# separately. Regex is from perldoc -q 'is a number'.
  my ($number, $padding, $rest) =
    $phrase =~ /^(\s*(?:[+-]?)(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee](?:[+-]?\d+))?)(\s*)(.*)$/;

  my $tagged;
  $tagger ||= Lingua::EN::Tagger->new;

  if ($number && $number != 1) {
    $tagged = $number . $padding . $tagger->get_readable($rest);
  }
  else {
    $tagged = $tagger->get_readable($phrase);
  }

  my $force_singular = $tagged =~ m{
    ^ \s* (?:(?:a|the)/DET)?
    \s* (?:1|one)/(?:JJ|NN|CD)\b
    (?!\s* (?:\S+/CC\b | [0-9/]+/CD\b))
  }x;

  my ($noun, $tag);

# last noun (or verb that could be a noun) before a preposition/conjunction
# or last noun/verb
  if ((($noun) = $tagged =~ m{$NOUN (?!.*/(?:NN|CD|JJ).*/(?:CC|IN)) .* /(?:CC|IN)}x) or
      (($noun) = $tagged =~ m{$NOUN (?!.*/(?:NN|CD|JJ))}x) or
      (($noun) = $tagged =~ m{$MAYBE_NOUN (?!.*/(?:NN|CD|JJ).*/(?:CC|IN)) .* /(?:CC|IN)}x) or
      (($noun) = $tagged =~ m{$MAYBE_NOUN (?!.*/(?:NN|CD|JJ))}x) or
      (($noun) = $tagged =~ m{$NOUN_OR_VERB (?!.*/(?:NN|CD|JJ|VB[A-Z]?).*/(?:CC|IN)) .* /(?:CC|IN)}x) or
      (($noun) = $tagged =~ m{$NOUN_OR_VERB (?!.*/(?:NN|CD|JJ|VB[A-Z]?))}x)) {
    my @pos = ($-[1], $+[1]);
    my $inflected_noun;

# special case "belongs to" (and in the future, some other verbs)
    if ($noun =~ /^(?:belongs)\z/i) {
      return $phrase;
    }

# special case phrases like "2 right braces" or "2 negative acknowledges"
# also we want "logs" to be treated as a noun usually
    if ($noun =~ /^(?:right|negative)\z/i || $phrase =~ /\blogs\b/i) {
      (($noun) = $tagged =~ m{$NOUN_OR_VERB (?!.*/(?:NN|CD|JJ|VB[A-Z]?).*/(?:CC|IN)) .* /(?:CC|IN)}x) or
      (($noun) = $tagged =~ m{$NOUN_OR_VERB (?!.*/(?:NN|CD|JJ|VB[A-Z]?))}x);

      @pos = ($-[1], $+[1]);
    }

# fix "people" and "heroes"
    if ($noun =~ /^(?:people|person)\z/i) {
      $inflected_noun = $want_singular ? 'person' : 'people';
    }
    elsif ($noun =~ /^hero(?:es)?\z/i) {
      $inflected_noun = $want_singular ? 'hero' : 'heroes';
    }
    elsif ($want_singular && lc($noun) eq 'aliases') {
      $inflected_noun = 'alias';
    }
    elsif ($want_singular && lc($noun) eq 'statuses') {
      $inflected_noun = 'status';
    }
    elsif ($force_singular) {
      $inflected_noun = Lingua::EN::Inflect::Number::to_S($noun);
    }
    else {
      my $is_plural = Lingua::EN::Inflect::Number::number($noun) ne 's';

      $inflected_noun = _inflect_noun($noun, $is_plural, $want_plural, $method);
    }

    substr($tagged, $pos[0], ($pos[1] - $pos[0])) = $inflected_noun if $inflected_noun;

    ($phrase = $tagged) =~ s{/[A-Z]+}{}g;
  }
# fallback
  else {
    my $number = Lingua::EN::Inflect::Number::number($phrase);

    if ($force_singular) {
      $phrase = Lingua::EN::Inflect::Number::to_S($phrase);
    }
    elsif (($want_plural && $number ne 'p') || ($want_singular && $number ne 's')) {
      $phrase = $phrase->$method;
    }
  }

  return $phrase;
}

=head2 to_PL

Attempts to pluralizes a phrase unless already plural.

=cut

sub to_PL {
  return _inflect(shift, 1, \&Lingua::EN::Inflect::Number::to_PL);
}

=head2 to_S

Attempts to singularize a phrase unless already singular.

=cut

sub to_S {
  return _inflect(shift, 0, \&Lingua::EN::Inflect::Number::to_S);
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-en-inflect-phrase at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-EN-Inflect-Phrase>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

More information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-EN-Inflect-Phrase>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-EN-Inflect-Phrase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-EN-Inflect-Phrase>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-EN-Inflect-Phrase/>

=back

=head1 REPOSITORY

  git clone git://github.com/rkitover/lingua-en-inflect-phrase.git lingua-en-inflect-phrase

=head1 SEE ALSO

L<Lingua::EN::Inflect>, L<Lingua::EN::Inflect::Number>, L<Lingua::EN::Tagger>

=head1 AUTHOR

Rafael Kitover <rkitover@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Rafael Kitover (rkitover@cpan.org).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
# vim:et sts=2 sw=2 tw=0:
