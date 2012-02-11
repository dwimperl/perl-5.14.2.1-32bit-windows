use strict;
use warnings;
package Sub::Exporter::ForMethods;
our $VERSION = '0.100050';
# ABSTRACT: helper routines for using Sub::Exporter to build methods

use Sub::Name ();

use Sub::Exporter -setup => {
  exports => [ qw(method_installer) ],
};


sub method_installer { 
  sub { 
    my ($arg, $to_export) = @_; 

    my $into = $arg->{into};

    for (my $i = 0; $i < @$to_export; $i += 2) {
      my ($as, $code) = @$to_export[ $i, $i+1 ];
      
      next if ref $as;

      $to_export->[ $i + 1 ] = Sub::Name::subname(
        join(q{::}, $into, $as),
        sub { $code->(@_) },
      );
    }
 
    Sub::Exporter::default_installer($arg, $to_export); 
  }; 
} 

1;

__END__
=pod

=head1 NAME

Sub::Exporter::ForMethods - helper routines for using Sub::Exporter to build methods

=head1 VERSION

version 0.100050

=head1 SYNOPSIS

In an exporting library:

  package Method::Builder;

  use Sub::Exporter::ForMethods qw(method_installer);

  use Sub::Exporter -setup => {
    exports   => [ method => \'_method_generator' ],
    installer => method_installer,
  };

  sub _method_generator {
    my ($self, $name, $arg, $col) = @_;
    return sub { ... };
  };

In an importing library:

  package Vehicle::Autobot;
  use Method::Builder method => { -as => 'transform' };

=head1 DESCRIPTION

The synopsis section, above, looks almost indistinguishable from any other
use of L<Sub::Exporter|Sub::Exporter>, apart from the use of
C<method_installer>.  It is nearly indistinguishable in behavior, too.  The
only change is that subroutines exported from Method::Builder into named slots
in Vehicle::Autobot will be wrapped in a subroutine called
C<Vehicle::Autobot::transform>.  This will insert a named frame into stack
traces to aid in debugging.

More importantly (for the author, anyway), they will not be removed by
L<namespace::autoclean|namespace::autoclean>.  This makes the following code
work:

  package MyLibrary;

  use Math::Trig qw(tan);         # uses Exporter.pm
  use String::Truncate qw(trunc); # uses Sub::Exporter's defaults

  use Sub::Exporter::ForMethods qw(method_installer);
  use Mixin::Linewise { installer => method_installer }, qw(read_file);

  use namespace::autoclean;

  ...

  1;

After MyLibrary is compiled, C<namespace::autoclean> will remove C<tan> and
C<trunc> as foreign contaminants, but will leave C<read_file> in place.  It
will also remove C<method_installer>, an added win.

=head1 EXPORTS

Sub::Exporter::ForMethods offers only one routine for export, and it may also
be called by its full package name:

=head2 method_installer

This routine returns an installer suitable for use as the C<installer> argument
to Sub::Exporter.  It updates the C<\@to_export> argument to wrap all code that
will be installed by name in a named subroutine, then passes control to the
default Sub::Exporter installer.

=head1 AUTHOR

  Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

