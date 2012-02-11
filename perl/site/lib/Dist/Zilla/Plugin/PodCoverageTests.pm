package Dist::Zilla::Plugin::PodCoverageTests;
{
  $Dist::Zilla::Plugin::PodCoverageTests::VERSION = '4.300007';
}
# ABSTRACT: a release test for Pod coverage
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

use namespace::autoclean;


__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Dist::Zilla::Plugin::PodCoverageTests - a release test for Pod coverage

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/release/pod-coverage.t - a standard Test::Pod::Coverage test

This test uses L<Pod::Coverage::TrustPod> to check your Pod coverage.  This
means that to indicate that some subs should be treated as covered, even if no
documentation can be found, you can add:

  =for Pod::Coverage sub_name other_sub this_one_too

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
___[ xt/release/pod-coverage.t ]___
#!perl

use Test::More;

eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
  if $@;

eval "use Pod::Coverage::TrustPod";
plan skip_all => "Pod::Coverage::TrustPod required for testing POD coverage"
  if $@;

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::TrustPod' });
