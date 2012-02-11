package Dist::Zilla::Plugin::ExtraTests;
{
  $Dist::Zilla::Plugin::ExtraTests::VERSION = '4.300007';
}
# ABSTRACT: rewrite ./xt tests to ./t tests with skips
use Moose;
with 'Dist::Zilla::Role::FileMunger';

use namespace::autoclean;


sub munge_file {
  my ($self, $file) = @_;

  return unless $file->name =~ m{\Axt/(smoke|author|release)/.+\.t\z};
  my $method = "_rewrite_$1\_test";

  $self->log("rewriting $1 test " . $file->name);

  $self->$method($file);
}

sub _rewrite_smoke_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'AUTOMATED_TESTING', '"smoke bot" testing');
}

sub _rewrite_author_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'AUTHOR_TESTING', 'testing by the author');
}

sub _rewrite_release_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'RELEASE_TESTING', 'release candidate testing');
}

sub _rewrite {
  my ($self, $file, $env, $msg) = @_;

  (my $name = $file->name) =~ s{^xt/([^/]+)/}{t/$1-};

  $file->name($name);

  my @lines = split /\n/, $file->content;
  my $after = $lines[0] =~ /\A#!/ ? 1 : 0;
  splice @lines, $after, 0, qq|
BEGIN {
  unless (\$ENV{$env}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for $msg');
  }
}
|;

  $file->content(join "\n", @lines, '');
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::ExtraTests - rewrite ./xt tests to ./t tests with skips

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This plugin rewrites tests found in the following directories:

  ./xt/author  - tests for author testing (env AUTHOR_TESTING is true)
  ./xt/release - tests for pre-release testers (env RELEASE_TESTING is true)
  ./xt/smoke   - tests for automated testers (env AUTOMATED_TESTING is true)

The tests are renamed and moved to F<./t>, and they are rewritten to include
some simple Perl code to skip all included tests if the correct env vars are
not set.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

