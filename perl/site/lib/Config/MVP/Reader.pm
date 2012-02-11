package Config::MVP::Reader;
BEGIN {
  $Config::MVP::Reader::VERSION = '2.200001';
}
use Moose;
# ABSTRACT: object to read config from storage into an assembler

use Config::MVP::Assembler;


sub read_config {
  my ($self, $location, $arg) = @_;
  $arg ||= {};

  $self = $self->new unless blessed $self;

  my $assembler = $arg->{assembler} || $self->build_assembler;

  $self->read_into_assembler($location, $assembler);

  return $assembler->sequence;
}


sub read_into_assembler {
  confess 'required method read_into_assembler unimplemented'
}


sub build_assembler { Config::MVP::Assembler->new; }

no Moose;
1;

__END__
=pod

=head1 NAME

Config::MVP::Reader - object to read config from storage into an assembler

=head1 VERSION

version 2.200001

=head1 SYNOPSIS

  use Config::MVP::Reader::YAML; # this doesn't really exist

  my $reader   = Config::MVP::Reader::YAML->new;

  my $sequence = $reader->read_config('/etc/foobar.yml');

=head1 DESCRIPTION

A Config::MVP::Reader exists to read configuration data from storage (like a
file) and convert that data into instructions to a L<Config::MVP::Assembler>,
which will in turn convert them into a L<Config::MVP::Sequence>, the final
product.

=head1 METHODS

=head2 read_config

  my $sequence = $reader->read_config($location, \%arg);

This method is passed a location, which has no set meaning, but should be the
mechanism by which the Reader is told how to locate configuration.  It might be
a file name, a hashref of parameters, a DBH, or anything else, depending on the
needs of the specific Reader subclass.

It is also passed a hashref of arguments, of which there is only one valid
argument:

 assembler - the Assembler object into which to read the config

If no assembler argument is passed, one will be constructed by calling the
Reader's C<build_assembler> method.

Subclasses should generally not override C<read_config>, but should instead
implement a C<read_into_assembler> method, described below.

=head2 read_into_assembler

This method should not be called directly.  It is called by C<read_config> with
the following parameters:

  my $sequence = $reader->read_into_assembler( $location, $assembler );

The method should read the configuration found at C<$location> and use it to
instruct the C<$assembler> (a L<Config::MVP::Assembler>) what configuration to
perform.

The default implementation of this method will throw an exception complaining
that it should have been implemented by a subclass.

=head2 build_assembler

If no Assembler is provided to C<read_config>'s C<assembler> parameter, this
method will be called on the Reader to construct one.

It must return a Config::MVP::Assembler object, and by default will return an
entirely generic one.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

