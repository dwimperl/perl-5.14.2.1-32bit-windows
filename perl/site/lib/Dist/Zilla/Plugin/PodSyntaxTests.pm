package Dist::Zilla::Plugin::PodSyntaxTests;
{
  $Dist::Zilla::Plugin::PodSyntaxTests::VERSION = '4.300007';
}
# ABSTRACT: a release test for Pod syntax
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

use namespace::autoclean;


__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Dist::Zilla::Plugin::PodSyntaxTests - a release test for Pod syntax

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/release/pod-syntax.t   - a standard Test::Pod test

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
___[ xt/release/pod-syntax.t ]___
#!perl
use Test::More;

eval "use Test::Pod 1.41";
plan skip_all => "Test::Pod 1.41 required for testing POD" if $@;

all_pod_files_ok();
