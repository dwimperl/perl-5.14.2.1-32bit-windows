package Config::MVP::Assembler;
BEGIN {
  $Config::MVP::Assembler::VERSION = '2.200001';
}
use Moose;
# ABSTRACT: multivalue-property config-loading state machine

use Config::MVP::Error;
use Config::MVP::Sequence;
use Config::MVP::Section;


has sequence_class => (
  is   => 'ro',
  isa  => 'ClassName',
  lazy => 1,
  default => 'Config::MVP::Sequence',
);


has section_class => (
  is   => 'ro',
  isa  => 'ClassName',
  lazy => 1,
  default => 'Config::MVP::Section',
);


has sequence => (
  is  => 'ro',
  isa => 'Config::MVP::Sequence',
  default  => sub { $_[0]->sequence_class->new({ assembler => $_[0] }) },
  init_arg => undef,
  handles  => [ qw(is_finalized finalize) ],
);

before finalize => sub {
  my ($self) = @_;

  $self->end_section if $self->current_section;
};


has _between_sections => (
  is  => 'rw',
  isa => 'Bool',
  default => 0,
);

sub begin_section {
  my ($self, $package_moniker, $name) = @_;

  Config::MVP::Error->throw("can't begin a new section while a section is open")
    if $self->current_section;

  $name = $package_moniker unless defined $name and length $name;

  my $package = ref($package_moniker)
              ? $$package_moniker
              : $self->expand_package($package_moniker);

  my $section = $self->section_class->new({
    name    => $name,
    (defined $package ? (package => $package) : ()),
  });

  $self->_between_sections(0);
  $self->sequence->add_section($section);
}


sub end_section {
  my ($self) = @_;

  Config::MVP::Error->throw("can't end a section when no section is active")
    unless $self->current_section;

  $self->current_section->finalize;

  $self->_between_sections(1);
}


sub change_section {
  my $self = shift;

  $self->end_section if $self->current_section;
  $self->begin_section(@_);
}


sub add_value {
  my ($self, $name, $value) = @_;

  Config::MVP::Error->throw("can't set value when no section is active")
    unless my $section = $self->current_section;

  $section->add_value($name => $value);
}


sub expand_package { $_[1] }


sub current_section {
  my ($self) = @_;

  return if $self->_between_sections;
  my (@sections) = $self->sequence->sections;
  return $sections[ -1 ] if @sections;

  return;
}

no Moose;
1;

__END__
=pod

=head1 NAME

Config::MVP::Assembler - multivalue-property config-loading state machine

=head1 VERSION

version 2.200001

=head1 DESCRIPTION

First, you should probably read the L<example of using
Config::MVP|Config::MVP/EXAMPLE>.  If you already know how it works, keep
going.

Config::MVP::Assembler is a helper for constructing a Config::MVP::Sequence
object.  It's a very simple state machine that lets you signal what kind of
events you've encountered while reading configuration.

=head1 ATTRIBUTES

=head2 sequence_class

This attribute stores the name of the class to be used for the assembler's
sequence.  It defaults to Config::MVP::Sequence.

=head2 section_class

This attribute stores the name of the class to be used for sections created by
the assembler.  It defaults to Config::MVP::Section.

=head2 sequence

This is the sequence that the assembler is assembling.  It defaults to a new
instance of the assembler's C<sequence_class>.

=head1 METHODS

=head2 begin_section

  $assembler->begin_section($package_moniker, $name);

  $assembler->begin_section($package_moniker);

  $assembler->begin_section( \$package );

This method tells the assembler that it should begin work on a new section with
the given identifier.  If it is already working on a section, an error will be
raised.  See C<L</change_section>> for a method to begin a new section, ending
the current one if needed.

The package moniker is expanded by the C<L</expand_package>> method.  The name,
if not given, defaults to the package moniker.  These data are used to create a
new section and the section is added to the end of the sequence.  If the
package argument is a reference, it is used as the literal value for the
package, and no expansion is performed.  If it is a reference to undef, a
section with no package is created.

=head2 end_section

  $assembler->end_section;

This ends the current section.  If there is no current section, an exception is
raised.

=head2 change_section

  $assembler->change_section($package_moniker, $name);

  $assembler->change_section($package_moniker);

This method calls C<begin_section>, first calling C<end_section> if needed.

=head2 add_value

  $assembler->add_value( $name => $value );

This method tells the assembler that it has encountered a named value and
should add it to the current section.  If there is no current section, an
exception is raised.  (If this is not the first time we've seen the name in the
section and it's not a multivalue property, the section class will raise an
exception on its own.)

=head2 expand_package

This method is passed a short identifier for a package and is expected to
return the full name of the module to load and package to interrogate.  By
default it simply returns the name it was passed, meaning that package names
must be given whole to the C<change_section> method.

=head2 current_section

This returns the section object onto which the assembler is currently adding
values.  If no section has yet been created, this method will return false.

=head1 TYPICAL USE

  my $assembler = Config::MVP::Assembler->new;

  # Maybe you want a starting section:
  my $starting_section = $assembler->section_class->new({ name => '_' });
  $assembler->sequence->add_section($section_starting);

  # We'll add some values, which will go to the starting section:
  $assembler->add_value(x => 10);
  $assembler->add_value(y => 20);

  # Change to a new section...
  $assembler->change_section($moniker);

  # ...and add values to that section.
  $assembler->add_value(x => 100);
  $assembler->add_value(y => 200);

The code above creates an assembler and populates it step by step.  In the end,
to get values, you could do something like this:

  my @output;

  for my $section ($assembler->sequence->sections) {
    push @output, [ $section->name, $section->package, $section->payload ];
  }

When changing sections, the given section "moniker" is used for the new section
name.  The result of passing that moniker to the assembler's
C<L</expand_package>> method is used as the section's package name.  (By
default, this method does nothing.)  The new section's C<multivalue_args> and
C<aliases> are determined by calling the C<mvp_multivalue_args> and
C<mvp_aliases> methods on the package.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

