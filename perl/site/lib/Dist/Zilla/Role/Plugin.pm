package Dist::Zilla::Role::Plugin;
{
  $Dist::Zilla::Role::Plugin::VERSION = '4.300007';
}
# ABSTRACT: something that gets plugged in to Dist::Zilla
use Moose::Role;
with 'Dist::Zilla::Role::ConfigDumper';

use Params::Util qw(_HASHLIKE);
use Moose::Autobox;
use MooseX::Types;

use namespace::autoclean;


has plugin_name => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);


has zilla => (
  is  => 'ro',
  isa => class_type('Dist::Zilla'),
  required => 1,
  weak_ref => 1,
);


has logger => (
  is   => 'ro',
  lazy => 1,
  handles => [ qw(log log_debug log_fatal) ],
  default => sub {
    $_[0]->zilla->chrome->logger->proxy({
      proxy_prefix => '[' . $_[0]->plugin_name . '] ',
    });
  },
);

# We define these effectively-pointless subs here to allow other roles to
# modify them with around. -- rjbs, 2010-03-21
sub mvp_multivalue_args {};
sub mvp_aliases         { return {} };

sub plugin_from_config {
  my ($class, $name, $arg, $section) = @_;

  my $self = $class->new(
    $arg->merge({
      plugin_name => $name,
      zilla       => $section->sequence->assembler->zilla,
    }),
  );
}

sub register_component {
  my ($class, $name, $arg, $section) = @_;

  my $self = $class->plugin_from_config($name, $arg, $section);

  my $version = $self->VERSION || 0;

  $self->log_debug([ 'online, %s v%s', $self->meta->name, $version ]);

  $self->zilla->plugins->push($self);

  return;
}

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::Plugin - something that gets plugged in to Dist::Zilla

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

The Plugin role should be applied to all plugin classes.  It provides a few key
methods and attributes that all plugins will need.

=head1 ATTRIBUTES

=head2 plugin_name

The plugin name is generally determined when configuration is read.

=head2 zilla

This attribute contains the Dist::Zilla object into which the plugin was
plugged.

=head1 METHODS

=head2 log

The plugin's C<log> method delegates to the Dist::Zilla object's
L<Dist::Zilla/log> method after including a bit of argument-munging.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

