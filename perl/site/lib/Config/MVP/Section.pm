package Config::MVP::Section;
BEGIN {
  $Config::MVP::Section::VERSION = '2.200001';
}
use Moose 0.91;

use Class::Load 0.06 ();
use Config::MVP::Error;

# ABSTRACT: one section of an MVP configuration sequence


has name => (
  is  => 'ro',
  isa => 'Str',
  required => 1
);


has package => (
  is  => 'ro',
  isa => 'Str', # should be class-like string, but can't be ClassName
  required  => 0,
  predicate => 'has_package',
);


has multivalue_args => (
  is   => 'ro',
  isa  => 'ArrayRef',
  lazy => 1,
  default => sub {
    my ($self) = @_;

    return []
      unless $self->has_package and $self->package->can('mvp_multivalue_args');

    return [ $self->package->mvp_multivalue_args ];
  },
);


has aliases => (
  is   => 'ro',
  isa  => 'HashRef',
  lazy => 1,
  default => sub {
    my ($self) = @_;

    return {} unless $self->has_package and $self->package->can('mvp_aliases');

    return $self->package->mvp_aliases;
  },
);


has payload => (
  is  => 'ro',
  isa => 'HashRef',
  init_arg => undef,
  default  => sub { {} },
);


has is_finalized => (
  is  => 'ro',
  isa => 'Bool',
  traits   => [ 'Bool' ],
  init_arg => undef,
  default  => 0,
  handles  => { finalize => 'set' },
);

before finalize => sub {
  my ($self) = @_;

  Config::MVP::Error->throw("can't finalize unsequenced Config::MVP::Section")
    unless $self->sequence;
};


has sequence => (
  is  => 'ro',
  isa => 'Config::MVP::Sequence',
  weak_ref  => 1,
  predicate => '_sequence_has_been_set',
  reader    => '_sequence',
  writer    => '__set_sequence',
  clearer   => '_clear_sequence',
);

sub _set_sequence {
  my ($self, $seq) = @_;

  Config::MVP::Error->throw("Config::MVP::Section cannot be resequenced")
    if $self->sequence;

  $self->__set_sequence($seq);
}

sub sequence {
  my ($self) = @_;
  return undef unless $self->_sequence_has_been_set;
  my $seq = $self->_sequence;

  Config::MVP::Error->throw("can't access section's destroyed sequence")
    unless defined $seq;

  return $seq;
}


sub add_value {
  my ($self, $name, $value) = @_;

  confess "can't add values to finalized section " . $self->name
    if $self->is_finalized;

  my $alias = $self->aliases->{ $name };
  $name = $alias if defined $alias;

  my $mva = $self->multivalue_args;

  if (grep { $_ eq $name } @$mva) {
    my $array = $self->payload->{$name} ||= [];
    push @$array, $value;
    return;
  }

  if (exists $self->payload->{$name}) {
    Carp::croak "multiple values given for property $name in section "
              . $self->name;
  }

  $self->payload->{$name} = $value;
}


sub load_package {
  my ($self, $package, $plugin) = @_;

  Class::Load::load_optional_class($package)
    or $self->missing_package($plugin, $package);
}


sub missing_package {
  my ($self, $package, $plugin) = @_ ;

  my $class = Moose::Meta::Class->create_anon_class(
    superclasses => [ 'Config::MVP::Error' ],
    cached       => 1,
    attributes   => [
      Moose::Meta::Attribute->new(package => (
        is       => 'ro',
        required => 1,
      )),
    ],
  );

  $class->name->throw({
    ident   => 'package not installed',
    message => "$package (for plugin $plugin) does not appear to be installed",
    package => $package,
  });
}

sub _BUILD_package_settings {
  my ($self) = @_;

  return unless defined (my $pkg = $self->package);

  confess "illegal package name $pkg" unless Params::Util::_CLASS($pkg);

  $self->load_package($pkg, $self->name);

  # We call these accessors for lazy attrs to ensure they're initialized from
  # defaults if needed.  Crash early! -- rjbs, 2009-08-09
  $self->multivalue_args;
  $self->aliases;
}

sub BUILD {
  my ($self) = @_;
  $self->_BUILD_package_settings;
}

no Moose;
1;

__END__
=pod

=head1 NAME

Config::MVP::Section - one section of an MVP configuration sequence

=head1 VERSION

version 2.200001

=head1 DESCRIPTION

For the most part, you can just consult L<Config::MVP> to understand what this
class is and how it's used.

=head1 ATTRIBUTES

=head2 name

This is the section's name.  It's a string, and it must be provided.

=head2 package

This is the (Perl) package with which the section is associated.  It is
optional.  When the section is instantiated, it will ensure that this package
is loaded.

=head2 multivalue_args

This attribute is an arrayref of value names that should be considered
multivalue properties in the section.  When added to the section, they will
always be wrapped in an arrayref, and they may be added to the section more
than once.

If this attribute is not given during construction, it will default to the
result of calling section's package's C<mvp_multivalue_args> method.  If the
section has no associated package or if the package doesn't provide that
method, it default to an empty arrayref.

=head2 aliases

This attribute is a hashref of name remappings.  For example, if it contains
this hashref:

  {
    file => 'files',
    path => 'files',
  }

Then attempting to set either the "file" or "path" setting for the section
would actually set the "files" setting.

If this attribute is not given during construction, it will default to the
result of calling section's package's C<mvp_aliases> method.  If the
section has no associated package or if the package doesn't provide that
method, it default to an empty hashref.

=head2 payload

This is the storage into which properties are set.  It is a hashref of names
and values.  You should probably not alter the contents of the payload, and
should read its contents only.

=head2 is_finalized

This attribute is true if the section has been marked finalized, which will
prevent any new values from being added to it.  It can be set with the
C<finalize> method.

=head2 sequence

This attributes points to the sequence into which the section has been
assembled.  It may be unset if the section has been created but not yet placed
in a sequence.

=head1 METHODS

=head2 add_value

  $section->add_value( $name => $value );

This method sets the value for the named property to the given value.  If the
property is a multivalue property, the new value will be pushed onto the end of
an arrayref that will store all values for that property.

Attempting to add a value for a non-multivalue property whose value was already
added will result in an exception.

=head2 load_package

  $section->load_package($package, $plugin);

This method is used to ensure that the given C<$package> is loaded, and is
called whenever a section with a package is created.  By default, it delegates
to L<Class::Load>.  If the package can't be found, it calls the
L<missing_package> method.  Errors in compilation are not suppressed.

=head2 missing_package

  $section->missing_package($package, $plugin);

This method is called when C<load_package> encounters a package that is not
installed.  By default, it throws an exception.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

