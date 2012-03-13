
package MooseX::AttributeHelpers;

our $VERSION   = '0.23';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:STEVAN';

use Moose 0.56 ();

use MooseX::AttributeHelpers::Meta::Method::Provided;
use MooseX::AttributeHelpers::Meta::Method::Curried;

use MooseX::AttributeHelpers::Trait::Bool;
use MooseX::AttributeHelpers::Trait::Counter;
use MooseX::AttributeHelpers::Trait::Number;
use MooseX::AttributeHelpers::Trait::String;
use MooseX::AttributeHelpers::Trait::Collection::List;
use MooseX::AttributeHelpers::Trait::Collection::Array;
use MooseX::AttributeHelpers::Trait::Collection::Hash;
use MooseX::AttributeHelpers::Trait::Collection::ImmutableHash;
use MooseX::AttributeHelpers::Trait::Collection::Bag;

use MooseX::AttributeHelpers::Counter;
use MooseX::AttributeHelpers::Number;
use MooseX::AttributeHelpers::String;
use MooseX::AttributeHelpers::Bool;
use MooseX::AttributeHelpers::Collection::List;
use MooseX::AttributeHelpers::Collection::Array;
use MooseX::AttributeHelpers::Collection::Hash;
use MooseX::AttributeHelpers::Collection::ImmutableHash;
use MooseX::AttributeHelpers::Collection::Bag;

1;

__END__

=pod

=head1 NAME

MooseX::AttributeHelpers - Extend your attribute interfaces (deprecated)

=head1 SYNOPSIS

  package MyClass;
  use Moose;
  use MooseX::AttributeHelpers;

  has 'mapping' => (
      metaclass => 'Collection::Hash',
      is        => 'rw',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      provides  => {
          exists    => 'exists_in_mapping',
          keys      => 'ids_in_mapping',
          get       => 'get_mapping',
          set       => 'set_mapping',
      },
      curries  => {
          set       => { set_quantity => [ 'quantity' ] }
      }
  );


  # ...

  my $obj = MyClass->new;
  $obj->set_quantity(10);      # quantity => 10
  $obj->set_mapping(4, 'foo'); # 4 => 'foo'
  $obj->set_mapping(5, 'bar'); # 5 => 'bar'
  $obj->set_mapping(6, 'baz'); # 6 => 'baz'


  # prints 'bar'
  print $obj->get_mapping(5) if $obj->exists_in_mapping(5);

  # prints '4, 5, 6'
  print join ', ', $obj->ids_in_mapping;

=head1 DESCRIPTION

B<This distribution is deprecated. The features it provides have been added to
the Moose core code as L<Moose::Meta::Attribute::Native>. This distribution
should not be used by any new code.>

While L<Moose> attributes provide you with a way to name your accessors,
readers, writers, clearers and predicates, this library provides commonly
used attribute helper methods for more specific types of data.

As seen in the L</SYNOPSIS>, you specify the extension via the 
C<metaclass> parameter. Available meta classes are:

=head1 PARAMETERS

=head2 provides

This points to a hashref that uses C<provider> for the keys and
C<method> for the values.  The method will be added to
the object itself and do what you want.

=head2 curries

This points to a hashref that uses C<provider> for the keys and
has two choices for the value:

You can supply C<< {method => [ @args ]} >> for the values.  The method will be
added to the object itself (always using C<@args> as the beginning arguments).

Another approach to curry a method provider is to supply a coderef instead of an
arrayref. The code ref takes C<$self>, C<$body>, and any additional arguments
passed to the final method.

  # ...

  curries => {
      grep => {
          times_with_day => sub {
              my ($self, $body, $datetime) = @_;
              $body->($self, sub { $_->ymd eq $datetime->ymd });
          }
      }
  }

  # ...

  $obj->times_with_day(DateTime->now); # takes datetime argument, checks day


=head1 METHOD PROVIDERS

=over

=item L<Number|MooseX::AttributeHelpers::Number>

Common numerical operations.

=item L<String|MooseX::AttributeHelpers::String>

Common methods for string operations.

=item L<Counter|MooseX::AttributeHelpers::Counter>

Methods for incrementing and decrementing a counter attribute.

=item L<Bool|MooseX::AttributeHelpers::Bool>

Common methods for boolean values.

=item L<Collection::Hash|MooseX::AttributeHelpers::Collection::Hash>

Common methods for hash references.

=item L<Collection::ImmutableHash|MooseX::AttributeHelpers::Collection::ImmutableHash>

Common methods for inspecting hash references.

=item L<Collection::Array|MooseX::AttributeHelpers::Collection::Array>

Common methods for array references.

=item L<Collection::List|MooseX::AttributeHelpers::Collection::List>

Common list methods for array references. 

=back

=head1 CAVEAT

This is an early release of this module. Right now it is in great need 
of documentation and tests in the test suite. However, we have used this 
module to great success at C<$work> where it has been tested very thoroughly
and deployed into a major production site.

I plan on getting better docs and tests in the next few releases, but until 
then please refer to the few tests we do have and feel free email and/or 
message me on irc.perl.org if you have any questions.

=head1 TODO

We need tests and docs badly.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

B<with contributions from:>

Robert (rlb3) Boone

Paul (frodwith) Driver

Shawn (Sartak) Moore

Chris (perigrin) Prather

Robert (phaylon) Sedlacek

Tom (dec) Lanyon

Yuval Kogman

Jason May

Cory (gphat) Watson

Florian (rafl) Ragwitz

Evan Carroll

Jesse (doy) Luehrs

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
