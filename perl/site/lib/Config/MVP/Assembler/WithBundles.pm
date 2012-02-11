package Config::MVP::Assembler::WithBundles;
BEGIN {
  $Config::MVP::Assembler::WithBundles::VERSION = '2.200001';
}
use Moose::Role;
# ABSTRACT: a role to make assemblers expand bundles

use Params::Util qw(_HASHLIKE _ARRAYLIKE);


sub package_bundle_method {
  my ($self, $pkg) = @_;
  return unless $pkg->can('mvp_bundle_config');
  return 'mvp_bundle_config';
}

after end_section => sub {
  my ($self) = @_;

  my $seq = $self->sequence;

  my ($last) = ($seq->sections)[-1];
  return unless $last->package;
  return unless my $method = $self->package_bundle_method($last->package);

  $self->replace_bundle_with_contents($last, $method);
};

sub replace_bundle_with_contents {
  my ($self, $bundle_sec, $method) = @_;

  my $seq = $self->sequence;

  $seq->delete_section($bundle_sec->name);

  $self->_add_bundle_contents($method, {
    name    => $bundle_sec->name,
    package => $bundle_sec->package,
    payload => $bundle_sec->payload,
  });
};

sub _add_bundle_contents {
  my ($self, $method, $arg) = @_;

  my @bundle_config = $arg->{package}->$method($arg);

  PLUGIN: for my $plugin (@bundle_config) {
    my ($name, $package, $payload) = @$plugin;

    Class::MOP::load_class($package);

    if (my $method = $self->package_bundle_method( $package )) {
      $self->_add_bundle_contents($method, {
        name    => $name,
        package => $package,
        payload => $payload,
      });
    } else {
      my $section = $self->section_class->new({
        name    => $name,
        package => $package,
      });

      if (_HASHLIKE($payload)) {
        # XXX: Clearly this is a hack. -- rjbs, 2009-08-24
        for my $name (keys %$payload) {
          my @v = ref $payload->{$name}
                ? @{$payload->{$name}}
                : $payload->{$name};
          $section->add_value($name => $_) for @v;
        }
      } elsif (_ARRAYLIKE($payload)) {
        for (my $i = 0; $i < @$payload; $i += 2) {
          $section->add_value(@$payload[ $i, $i + 1 ]);
        }
      } else {
        Carp::confess("don't know how to interpret section payload $payload");
      }

      $self->sequence->add_section($section);
      $section->finalize;
    }
  }
}

no Moose;
1;

__END__
=pod

=head1 NAME

Config::MVP::Assembler::WithBundles - a role to make assemblers expand bundles

=head1 VERSION

version 2.200001

=head1 DESCRIPTION

Config::MVP::Assembler::WithBundles is a role to be composed into a
Config::MVP::Assembler subclass.  It allows some sections of configuration to
be treated as bundles.  When any section is ended, if that section represented
a bundle, its bundle contents will be unrolled and will replace it in the
sequence.

A package is considered a bundle if the this returns a defined method:

  my $method = $assembler->package_bundle_method($package);

The default implementation looks for a method callde C<mvp_bundle_config>, but
C<package_bundle_method> can be replaced to allow for other bundle-identifying
information.

Bundles are expanded by a call to the assembler's
C<replace_bundle_with_contents> method, like this:

  $assembler->replace_bundle_with_contents($section, $method);

=head2 replace_bundle_with_contents

The default C<replace_bundle_with_contents> method deletes the section from the
sequence.  It then gets a description of the new sections to introduce, like
this:

  my @new_config = $bundle_section->package->$method({
    name    => $bundle_section->name,
    package => $bundle_section->package,
    payload => $bundle_section->payload,
  });

(We pass a hashref rather than a section so that bundles can be expanded
synthetically without having to laboriously create a new Section.)

The returned C<@new_config> is a list of arrayrefs, each of which has three
entries:

  [ $name, $package, $payload ]

Each arrayref is converted into a section in the sequence.  The C<$payload>
should be an arrayref of name/value pairs to be added to the created section.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

