package MooseX::Singleton::Role::Object;
BEGIN {
  $MooseX::Singleton::Role::Object::AUTHORITY = 'cpan:SARTAK';
}
{
  $MooseX::Singleton::Role::Object::VERSION = '0.29';
}
use Moose::Role;
use Carp qw( carp );


sub instance { shift->new }

sub initialize {
    my ( $class, @args ) = @_;

    my $existing = $class->meta->existing_singleton;
    confess "Singleton is already initialized" if $existing;

    return $class->new(@args);
}

override new => sub {
    my ( $class, @args ) = @_;

    my $existing = $class->meta->existing_singleton;
    confess "Singleton is already initialized" if $existing and @args;

    # Otherwise BUILD will be called repeatedly on the existing instance.
    # -- rjbs, 2008-02-03
    return $existing if $existing and !@args;

    return super();
};

sub _clear_instance {
    my ($class) = @_;
    $class->meta->clear_singleton;
}

no Moose::Role;

1;

# ABSTRACT: Object class role for MooseX::Singleton



=pod

=head1 NAME

MooseX::Singleton::Role::Object - Object class role for MooseX::Singleton

=head1 VERSION

version 0.29

=head1 DESCRIPTION

This just adds C<instance> as a shortcut for C<new>.

=head1 AUTHOR

Shawn M Moore <sartak@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


