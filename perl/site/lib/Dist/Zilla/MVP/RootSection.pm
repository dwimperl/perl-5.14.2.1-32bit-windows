package Dist::Zilla::MVP::RootSection;
{
  $Dist::Zilla::MVP::RootSection::VERSION = '4.300007';
}
use Moose;
extends 'Config::MVP::Section';
# ABSTRACT: a standard section in Dist::Zilla's configuration sequence

use namespace::autoclean;


use MooseX::LazyRequire;
use MooseX::SetOnce;
use Moose::Util::TypeConstraints;

has '+name'    => (default => '_');

has '+aliases' => (default => sub { return { author => 'authors' } });

has '+multivalue_args' => (default => sub { [ qw(authors) ] });

has zilla => (
  is     => 'ro',
  isa    => class_type('Dist::Zilla'),
  traits => [ qw(SetOnce) ],
  writer => 'set_zilla',
  lazy_required => 1,
);

after finalize => sub {
  my ($self) = @_;

  my $assembler = $self->sequence->assembler;

  my $zilla = $assembler->zilla_class->new( $self->payload );

  $self->set_zilla($zilla);
};

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::MVP::RootSection - a standard section in Dist::Zilla's configuration sequence

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This is a subclass of L<Config::MVP::Section>, used as the starting section by
L<Dist::Zilla::MVP::Assembler::Zilla>.  It has a number of useful defaults, as
well as a C<zilla> attribute which will, after section finalization, contain a
Dist::Zilla object with which subsequent plugin sections may register.

Those useful defaults are:

=over 4

=item *

name defaults to _

=item *

aliases defaults to { author => 'authors' }

=item *

multivalue_args defaults to [ 'authors' ]

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

