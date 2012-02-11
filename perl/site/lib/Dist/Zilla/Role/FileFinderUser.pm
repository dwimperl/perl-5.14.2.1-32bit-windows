package Dist::Zilla::Role::FileFinderUser;
{
  $Dist::Zilla::Role::FileFinderUser::VERSION = '4.300007';
}
# ABSTRACT: something that uses FileFinder plugins
use MooseX::Role::Parameterized;

use namespace::autoclean;



parameter finder_arg_names => (
  isa => 'ArrayRef',
  default => sub { [ 'finder' ] },
);


parameter default_finders => (
  isa => 'ArrayRef',
  required => 1,
);


parameter method => (
  isa     => 'Str',
  default => 'found_files',
);

role {
  my ($p) = @_;

  my ($finder_arg, @finder_arg_aliases) = @{ $p->finder_arg_names };
  confess "no finder arg names given!" unless $finder_arg;

  around mvp_multivalue_args => sub {
    my ($orig, $self) = @_;

    my @start = $self->$orig;
    return (@start, $finder_arg);
  };

  if (@finder_arg_aliases) {
    around mvp_aliases => sub {
      my ($orig, $self) = @_;

      my $start = $self->$orig;

      for my $alias (@finder_arg_aliases) {
        confess "$alias is already an alias to $start->{$alias}"
          if exists $start->{$alias} and $orig->{$alias} ne $finder_arg;
        $start->{ $alias } = $finder_arg;
      }

      return $start;
    };
  }

  has $finder_arg => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [ @{ $p->default_finders } ] },
  );

  method $p->method => sub {
    my ($self) = @_;

    my @filesets = map {; $self->zilla->find_files($_) }
                   @{ $self->$finder_arg };

    my %by_name = map {; $_->name, $_ } map { @$_ } @filesets;

    return [ values %by_name ];
  };
};

1;

__END__
=pod

=head1 NAME

Dist::Zilla::Role::FileFinderUser - something that uses FileFinder plugins

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This role enables you to search for files in the dist. This makes it easy to find specific
files and have the code factored out to common methods.

Here's an example of a finder: ( taken from AutoPrereqs )

  with 'Dist::Zilla::Role::FileFinderUser' => {
      default_finders  => [ ':InstallModules', ':ExecFiles' ],
  };

Then you use it in your code like this:

  foreach my $file ( $self->found_files ) {
    # $file is an object! Look at L<Dist::Zilla::Role::File>
  }

=head1 ATTRIBUTES

=head2 finder_arg_names

Define the name of the attribute which will hold this finder. Be sure to specify different names
if you have multiple finders!

This is an ArrayRef.

Default: [ qw( finder ) ]

=head2 default_finders

This attribute is an arrayref of plugin names for the default plugins the
consuming plugin will use as finder.s

Example: C<< [ qw( :InstallModules :ExecFiles ) ] >>

The default finders are:

=over 4

=item :InstallModules

Searches your lib/ directory for pm/pod files

=item :IncModules

Searches your inc/ directory for pm files

=item :MainModule

Finds the C<main_module> of your dist

=item :TestFiles

Searches your t/ directory and lists the files in it.

=item :ExecFiles

Searches your distribution for executable files.  Hint: Use the
L<Dist::Zilla::Plugin::ExecDir> plugin to mark those files as executables.

=item :ShareFiles

Searches your ShareDir directory and lists the files in it.
Hint: Use the L<Dist::Zilla::Plugin::ShareDir> plugin to setup the sharedir.

=back

=head2 method

This will be the name of the subroutine installed in your package for this
finder.  Be sure to specify different names if you have multiple finders!

Default: found_files

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

