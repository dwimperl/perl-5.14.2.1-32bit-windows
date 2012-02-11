package Dist::Zilla::Plugin::MetaTests;
{
  $Dist::Zilla::Plugin::MetaTests::VERSION = '4.300007';
}
# ABSTRACT: common extra tests for META.yml
use Moose;
extends 'Dist::Zilla::Plugin::InlineFiles';

use namespace::autoclean;


__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Dist::Zilla::Plugin::MetaTests - common extra tests for META.yml

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following files:

  xt/release/meta-yaml.t - a standard Test::CPAN::Meta test

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
___[ xt/release/distmeta.t ]___
#!perl

use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;
meta_yaml_ok();
