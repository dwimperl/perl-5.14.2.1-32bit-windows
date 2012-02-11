package Config::MVP::Reader::Finder;
BEGIN {
  $Config::MVP::Reader::Finder::VERSION = '2.200001';
}
use Moose;
extends 'Config::MVP::Reader';
# ABSTRACT: a reader that finds an appropriate file


use Config::MVP::Error;
use Module::Pluggable::Object;
use Try::Tiny;


sub default_search_path {
  return qw(Config::MVP::Reader)
}

has _module_pluggable_object => (
  is => 'ro',
  init_arg => undef,
  default  => sub {
    my ($self) = @_;
    Module::Pluggable::Object->new(
      search_path => [ $self->default_search_path ],
      inner       => 0,
      require     => 1,
    );
  },
);

sub _which_reader {
  my ($self, $location) = @_;

  my @options;

  for my $pkg ($self->_module_pluggable_object->plugins) {
    next unless $pkg->isa('Moose::Object');
    next unless $pkg->does('Config::MVP::Reader::Findable');

    my $location = $pkg->refined_location($location);

    next unless defined $location;

    push @options, [ $pkg, $location ];
  }

  Config::MVP::Error->throw("no viable configuration could be found")
    unless @options;

  # XXX: Improve this error message -- rjbs, 2010-05-24
  Config::MVP::Error->throw("multiple possible config plugins found")
    if @options > 1;

  return {
    'package'  => $options[0][0],
    'location' => $options[0][1],
  };
}

has if_none => (
  is  => 'ro',
  isa => 'Maybe[Str|CodeRef]',
);

sub read_config {
  my ($self, $location, $arg) = @_;
  $self = $self->new unless blessed($self);
  $arg ||= {};

  local $arg->{assembler} = $arg->{assembler} || $self->build_assembler;

  my $which;
  my $instead;
  try {
    $which = $self->_which_reader($location);
  } catch {
    die $_ unless $_ =~ /^no viable configuration/;
    die $_ unless defined (my $handler = $self->if_none);
    $instead = $self->$handler($location, $arg);
  };

  return $instead unless $which;

  my $reader = $which->{package}->new;

  return $reader->read_config( $which->{location}, $arg );
}

sub build_assembler { }

sub read_into_assembler {
  confess "This method should never be called or reachable";
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Config::MVP::Reader::Finder - a reader that finds an appropriate file

=head1 VERSION

version 2.200001

=head1 DESCRIPTION

The Finder reader multiplexes many other readers that implement the
L<Config::MVP::Reader::Findable> role.  It uses L<Module::Pluggable> to search
for modules, limits them to objects implementing the Findable role, and then
selects the those which report that they are able to read a configuration file
found in the config root directory.  If exactly one findable configuration
reader finds a file, it is used to read the file and the configuration sequence
is returned.  Otherwise, an exception is raised.

Config::MVP::Reader::Finder's C<build_assembler> method will decline a new
assembler, so if none was passed to C<read_config>, the Findable reader to
which reading is delegated will be responsible for building the assembler,
unless a Finder subclass overrides C<build_assembler> to set a default across
all possible delegates.

=head1 METHODS

=head2 default_search_path

This is the default search path used to find configuration readers.  This
method should return a list, and by default returns:

  qw( Config::MVP::Reader )

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

