package MooseX::Types::LoadableClass;
use strict;
use warnings;
use MooseX::Types -declare => [qw/ ClassName LoadableClass LoadableRole /];
use MooseX::Types::Moose qw(Str RoleName), ClassName => { -as => 'MooseClassName' };
use Moose::Util::TypeConstraints;
use Class::Load qw/ load_optional_class /;
use namespace::clean -except => [qw/ import /];

our $VERSION = '0.007';
$VERSION = eval $VERSION;

subtype LoadableClass, as MooseClassName;
coerce LoadableClass, from Str,
    via { my $name = $_; load_optional_class($name) ? $name : undef };

subtype LoadableRole, as RoleName;
# this is alright because ClassName is just is_class_loaded, with no
# constraints on the metaclass
coerce LoadableRole, from Str, via { to_LoadableClass($_) };

# back compat
__PACKAGE__->type_storage->{ClassName}
    = __PACKAGE__->type_storage->{LoadableClass};

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

MooseX::Types::LoadableClass - ClassName type constraint with coercion to load the class.

=head1 SYNOPSIS

    package MyClass;
    use Moose;
    use MooseX::Types::LoadableClass qw/ LoadableClass /;

    has foobar_class => (
        is => 'ro',
        required => 1,
        isa => LoadableClass,
        coerce => 1,
    );

    MyClass->new(foobar_class => 'FooBar'); # FooBar.pm is loaded or an
                                            # exception is thrown.

=head1 DESCRIPTION

    use Moose::Util::TypeConstraints;

    my $tc = subtype as ClassName;
    coerce $tc, from Str, via { Class::MOP::load_class($_); $_ };

I've written those three lines of code quite a lot of times, in quite
a lot of places.

Now I don't have to.

=head1 TYPES EXPORTED

=head2 LoadableClass

A normal class / package.

=head2 LoadableRole

Like C<LoadableClass>, except the loaded package must be a L<Moose::Role>.

=head1 AUTHORS

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

Florian Ragwitz (rafl) C<< <rafl@debian.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 the above named authors.

Licensed under the same terms as perl itself.

=cut

