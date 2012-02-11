package Dist::Zilla::MVP::Assembler::GlobalConfig;
{
  $Dist::Zilla::MVP::Assembler::GlobalConfig::VERSION = '4.300007';
}
use Moose;
extends 'Dist::Zilla::MVP::Assembler';
# ABSTRACT: Dist::Zilla::MVP::Assembler for global configuration

use namespace::autoclean;


has stash_registry => (
  is  => 'ro',
  isa => 'HashRef[Object]',
  default => sub { {} },
);


sub register_stash {
  my ($self, $name, $object) = @_;

  # $self->log_fatal("tried to register $name stash entry twice")
  confess("tried to register $name stash entry twice")
    if $self->stash_registry->{ $name };

  $self->stash_registry->{ $name } = $object;
  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::MVP::Assembler::GlobalConfig - Dist::Zilla::MVP::Assembler for global configuration

=head1 VERSION

version 4.300007

=head1 OVERVIEW

This is a subclass of L<Dist::Zilla::MVP::Assembler> used when assembling the
global configuration.  It has a C<stash_registry> attribute, a hashref, into
which stashes will be registered.

They get registered via the C<register_stash> method, below, generally called
by the C<register_component> method on L<Dist::Zilla::Role::Stash>-performing
class.

=head1 METHODS

=head2 register_stash

  $assembler->register_stash($name => $stash_object);

This adds a stash to the assembler's stash registry -- unless the name is
already taken, in which case an exception is raised.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

