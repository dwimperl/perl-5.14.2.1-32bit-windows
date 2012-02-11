package MooseX::StrictConstructor::Trait::Method::Constructor;
{
  $MooseX::StrictConstructor::Trait::Method::Constructor::VERSION = '0.19';
}

use Moose::Role;

use namespace::autoclean;

use B ();

around _generate_BUILDALL => sub {
    my $orig = shift;
    my $self = shift;

    my $source = $self->$orig();
    $source .= ";\n" if $source;

    my @attrs = '__INSTANCE__ => 1,';
    push @attrs, map { B::perlstring($_) . ' => 1,' }
        grep { defined }
        map  { $_->init_arg() } @{ $self->_attributes() };

    $source .= <<"EOF";
my \%attrs = (@attrs);

my \@bad = sort grep { ! \$attrs{\$_} }  keys \%{ \$params };

if (\@bad) {
    Moose->throw_error("Found unknown attribute(s) passed to the constructor: \@bad");
}
EOF

    return $source;
} if $Moose::VERSION < 1.9900;

1;

# ABSTRACT: A role to make immutable constructors strict



=pod

=head1 NAME

MooseX::StrictConstructor::Trait::Method::Constructor - A role to make immutable constructors strict

=head1 VERSION

version 0.19

=head1 DESCRIPTION

This role simply wraps C<_generate_BUILDALL()> (from
C<Moose::Meta::Method::Constructor>) so that immutable classes have a
strict constructor.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__


