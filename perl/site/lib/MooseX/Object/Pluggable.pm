package MooseX::Object::Pluggable;

use Carp;
use Moose::Role;
use Class::MOP;
use Scalar::Util 'blessed';
use Module::Pluggable::Object;

our $VERSION = '0.0011';

=head1 NAME

    MooseX::Object::Pluggable - Make your classes pluggable

=head1 SYNOPSIS

    package MyApp;
    use Moose;

    with 'MooseX::Object::Pluggable';

    ...

    package MyApp::Plugin::Pretty;
    use Moose::Role;

    sub pretty{ print "I am pretty" }

    1;

    #
    use MyApp;
    my $app = MyApp->new;
    $app->load_plugin('Pretty');
    $app->pretty;

=head1 DESCRIPTION

This module is meant to be loaded as a role from Moose-based classes
it will add five methods and four attributes to assist you with the loading
and handling of plugins and extensions for plugins. I understand that this may
pollute your namespace, however I took great care in using the least ambiguous
names possible.

=head1 How plugins Work

Plugins and extensions are just Roles by a fancy name. They are loaded at runtime
on demand and are instance, not class based. This means that if you have more than
one instance of a class they can all have different plugins loaded. This is a feature.

Plugin methods are allowed to C<around>, C<before>, C<after>
their consuming classes, so it is important to watch for load order as plugins can
and will overload each other. You may also add attributes through has.

Please note that when you load at runtime you lose the ability to wrap C<BUILD>
and roles using C<has> will not go through compile time checks like C<required>
and <default>.

Even though C<override> will work , I STRONGLY discourage it's use
and a warning will be thrown if you try to use it.
This is closely linked to the way multiple roles being applied is handled and is not
likely to change. C<override> bevavior is closely linked to inheritance and thus will
likely not work as you expect it in multiple inheritance situations. Point being,
save yourself the headache.

=head1 How plugins are loaded

When roles are applied at runtime an anonymous class will wrap your class and
C<$self-E<gt>blessed> and C<ref $self> will no longer return the name of your object,
they will instead return the name of the anonymous class created at runtime.
See C<_original_class_name>.

=head1 Usage

For a simple example see the tests included in this distribution.

=head1 Attributes

=head2 _plugin_ns

String. The prefix to use for plugin names provided. MyApp::Plugin is sensible.

=head2 _plugin_app_ns

ArrayRef, Accessor automatically dereferences into array on a read call.
By default will be filled with the class name and it's prescedents, it is used
to determine which directories to look for plugins as well as which plugins
take presedence upon namespace collitions. This allows you to subclass a pluggable
class and still use it's plugins while using yours first if they are available.

=head2 _plugin_locator

An automatically built instance of L<Module::Pluggable::Object> used to locate
available plugins.

=head2 _original_class_name

Because of the way roles apply C<$self-E<gt>blessed> and C<ref $self> will
no longer return what you expect. Instead, upon instantiation, the name of the
class instantiated will be stored in this attribute if you need to access the
name the class held before any runtime roles were applied.

=cut

#--------#---------#---------#---------#---------#---------#---------#---------#

has _plugin_ns => (
  is => 'rw',
  required => 1,
  isa => 'Str',
  default => sub{ 'Plugin' },
);

has _original_class_name => (
  is => 'ro',
  required => 1,
  isa => 'Str',
  default => sub{ blessed($_[0]) },
);

has _plugin_loaded => (
  is => 'rw',
  required => 1,
  isa => 'HashRef',
  default => sub{ {} }
);

has _plugin_app_ns => (
  is => 'rw',
  required => 1,
  isa => 'ArrayRef',
  lazy => 1,
  auto_deref => 1,
  builder => '_build_plugin_app_ns',
  trigger => sub{ $_[0]->_clear_plugin_locator if $_[0]->_has_plugin_locator; },
);

has _plugin_locator => (
  is => 'rw',
  required => 1,
  lazy => 1,
  isa => 'Module::Pluggable::Object',
  clearer => '_clear_plugin_locator',
  predicate => '_has_plugin_locator',
  builder => '_build_plugin_locator'
);

#--------#---------#---------#---------#---------#---------#---------#---------#

=head1 Public Methods

=head2 load_plugins @plugins

=head2 load_plugin $plugin

Load the apropriate role for C<$plugin>.

=cut

sub load_plugins {
    my ($self, @plugins) = @_;
    die("You must provide a plugin name") unless @plugins;

    my $loaded = $self->_plugin_loaded;
    my @load = grep { not exists $loaded->{$_} } @plugins;
    my @roles = map { $self->_role_from_plugin($_) } @load;

    return if @roles == 0;

    if ( $self->_load_and_apply_role(@roles) ) {
        @{ $loaded }{@load} = @roles;
        return 1;
    } else {
        return;
    }
}


sub load_plugin {
  my $self = shift;
  $self->load_plugins(@_);
}

=head1 Private Methods

There's nothing stopping you from using these, but if you are using them
for anything thats not really complicated you are probably doing
something wrong.

=head2 _role_from_plugin $plugin

Creates a role name from a plugin name. If the plugin name is prepended
with a C<+> it will be treated as a full name returned as is. Otherwise
a string consisting of C<$plugin>  prepended with the C<_plugin_ns>
and the first valid value from C<_plugin_app_ns> will be returned. Example

   #assuming appname MyApp and C<_plugin_ns> 'Plugin'
   $self->_role_from_plugin("MyPlugin"); # MyApp::Plugin::MyPlugin

=cut

sub _role_from_plugin{
    my ($self, $plugin) = @_;

    return $1 if( $plugin =~ /^\+(.*)/ );

    my $o = join '::', $self->_plugin_ns, $plugin;
    #Father, please forgive me for I have sinned.
    my @roles = grep{ /${o}$/ } $self->_plugin_locator->plugins;

    croak("Unable to locate plugin '$plugin'") unless @roles;
    return $roles[0] if @roles == 1;

    my $i = 0;
    my %presedence_list = map{ $i++; "${_}::${o}", $i } $self->_plugin_app_ns;

    @roles = sort{ $presedence_list{$a} <=> $presedence_list{$b}} @roles;

    return shift @roles;
}

=head2 _load_and_apply_role @roles

Require C<$role> if it is not already loaded and apply it. This is
the meat of this module.

=cut

sub _load_and_apply_role{
    my ($self, @roles) = @_;
    die("You must provide a role name") unless @roles;

    foreach my $role ( @roles ) {
        eval { Class::MOP::load_class($role) };
        confess("Failed to load role: ${role} $@") if $@;

        carp("Using 'override' is strongly discouraged and may not behave ".
            "as you expect it to. Please use 'around'")
        if scalar keys %{ $role->meta->get_override_method_modifiers_map };
    }

    Moose::Util::apply_all_roles( $self, @roles );

    return 1;
}

=head2 _build_plugin_app_ns

Automatically builds the _plugin_app_ns attribute with the classes in the
class presedence list that are not part of Moose.

=cut

sub _build_plugin_app_ns{
    my $self = shift;
    my @names = (grep {$_ !~ /^Moose::/} $self->meta->class_precedence_list);
    return \@names;
}

=head2 _build_plugin_locator

Automatically creates a L<Module::Pluggable::Object> instance with the correct
search_path.

=cut

sub _build_plugin_locator{
    my $self = shift;

    my $locator = Module::Pluggable::Object->new
        ( search_path =>
          [ map { join '::', ($_, $self->_plugin_ns) } $self->_plugin_app_ns ]
        );
    return $locator;
}

=head2 meta

Keep tests happy. See L<Moose>

=cut

1;

__END__;

=head1 SEE ALSO

L<Moose>, L<Moose::Role>, L<Class::Inspector>

=head1 AUTHOR

Guillermo Roditi, <groditi@cpan.org>

=head1 BUGS

Holler?

Please report any bugs or feature requests to
C<bug-moosex-object-pluggable at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Object-Pluggable>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX-Object-Pluggable

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Object-Pluggable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Object-Pluggable>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Object-Pluggable>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Object-Pluggable>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item #Moose - Huge number of questions

=item Matt S Trout <mst@shadowcatsystems.co.uk> - ideas / planning.

=item Stevan Little - EVERYTHING. Without him this would have never happened.

=item Shawn M Moore - bugfixes

=back

=head1 COPYRIGHT

Copyright 2007 Guillermo Roditi.  All Rights Reserved.  This is
free software; you may redistribute it and/or modify it under the same
terms as Perl itself.

=cut
