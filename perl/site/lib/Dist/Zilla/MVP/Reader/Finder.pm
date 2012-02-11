package Dist::Zilla::MVP::Reader::Finder;
{
  $Dist::Zilla::MVP::Reader::Finder::VERSION = '4.300007';
}
use Moose;
use Config::MVP::Reader 2.101540; # if_none
extends 'Config::MVP::Reader::Finder';
# ABSTRACT: the reader for dist.ini files

use namespace::autoclean;

use Dist::Zilla::MVP::Assembler;

sub default_search_path {
  return qw(Dist::Zilla::MVP::Reader Config::MVP::Reader);
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::MVP::Reader::Finder - the reader for dist.ini files

=head1 VERSION

version 4.300007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

