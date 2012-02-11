package MooseX::StrictConstructor;
{
  $MooseX::StrictConstructor::VERSION = '0.19';
}

use strict;
use warnings;

use Moose 0.94 ();
use Moose::Exporter;
use Moose::Util::MetaRole;

use MooseX::StrictConstructor::Trait::Class;
use MooseX::StrictConstructor::Trait::Method::Constructor;;

my %metaroles = (
    class => ['MooseX::StrictConstructor::Trait::Class'],
);

$metaroles{constructor}
    = ['MooseX::StrictConstructor::Trait::Method::Constructor']
    if $Moose::VERSION <= 1.9900;

Moose::Exporter->setup_import_methods( class_metaroles => \%metaroles );

1;

# ABSTRACT: Make your object constructors blow up on unknown attributes



=pod

=head1 NAME

MooseX::StrictConstructor - Make your object constructors blow up on unknown attributes

=head1 VERSION

version 0.19

=head1 SYNOPSIS

    package My::Class;

    use Moose;
    use MooseX::StrictConstructor;

    has 'size' => ...;

    # then later ...

    # this blows up because color is not a known attribute
    My::Class->new( size => 5, color => 'blue' );

=head1 DESCRIPTION

Simply loading this module makes your constructors "strict". If your
constructor is called with an attribute init argument that your class does not
declare, then it calls C<< Moose->throw_error() >>. This is a great way to
catch small typos.

=head2 Subverting Strictness

You may find yourself wanting to have your constructor accept a
parameter which does not correspond to an attribute.

In that case, you'll probably also be writing a C<BUILD()> or
C<BUILDARGS()> method to deal with that parameter. In a C<BUILDARGS()>
method, you can simply make sure that this parameter is not included
in the hash reference you return. Otherwise, in a C<BUILD()> method,
you can delete it from the hash reference of parameters.

  sub BUILD {
      my $self   = shift;
      my $params = shift;

      if ( delete $params->{do_something} ) {
          ...
      }
  }

=head1 BUGS

Please report any bugs or feature requests to
C<bug-moosex-strictconstructor@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.  I will be notified, and then
you'll automatically be notified of progress on your bug as I make
changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

