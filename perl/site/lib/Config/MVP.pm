package Config::MVP;
BEGIN {
  $Config::MVP::VERSION = '2.200001';
}
# ABSTRACT: multivalue-property package-oriented configuration
use strict;
use warnings;


1;

__END__
=pod

=head1 NAME

Config::MVP - multivalue-property package-oriented configuration

=head1 VERSION

version 2.200001

=head1 SYNOPSIS

If you want a useful synopsis, consider this code which actually comes from
L<Config::MVP::Assembler|Config::MVP::Assembler>:

  my $assembler = Config::MVP::Assembler->new;

  # Maybe you want a starting section:
  my $section = $assembler->section_class->new({ name => '_' });
  $assembler->sequence->add_section($section);

  # We'll add some values, which will go to the starting section:
  $assembler->add_value(x => 10);
  $assembler->add_value(y => 20);

  # Change to a new section...
  $assembler->change_section($moniker);

  # ...and add values to that section.
  $assembler->add_value(x => 100);
  $assembler->add_value(y => 200);

This doesn't make sense?  Well, read on.

=head1 DESCRIPTION

MVP is a mechanism for loading configuration (or other information) for
libraries.  It doesn't read a file or a database.  It's a helper for things
that do.

The idea is that you end up with a
L<Config::MVP::Sequence|Config::MVP::Sequence> object, and that you can use
that object to fully configure your library or application.  The sequence will
contain a bunch of L<Config::MVP::Section|Config::MVP::Section> objects, each
of which is meant to provide configuration for a part of your program.  Most of
these sections will be directly related to a Perl library that you'll use as a
plugin or helper.  Each section will have a name, and every name in the
sequence will be unique.

This is a pretty abstract set of behaviors, so we'll provide some more concrete
examples that should help explain how things work.

=head1 EXAMPLE

Imagine that we've got a program called DeliveryBoy that accepts mail and does
stuff with it.  The "stuff" is entirely up to the user's configuration.  He can
set up plugins that will be used on the message.  He write a config file that's
read by L<Config::INI::MVP::Reader|Config::INI::MVP::Reader>, which is a thin
wrapper around Config::MVP used to load MVP-style config from F<INI> files.

Here's the user's configuration:

  [Whitelist]
  require_pgp = 1

  file = whitelist-family
  file = whitelist-friends
  file = whitelist-work

  [SpamFilter]
  filterset = standard
  max_score = 5
  action    = bounce

  [SpamFilter / SpamFilter_2]
  filterset = aggressive
  max_score = 5
  action    = tag

  [VerifyPGP]

  [Deliver]
  dest = Maildir

The user will end up with a sequence with six sections, which we can represent
something like this:

  { name    => 'Whitelist',
    package => 'DeliveryBoy::Plugin::Whitelist',
    payload => {
      require_pgp => 1,
      files   => [ qw(whitelist-family whitelist-friends whitelist-work) ]
    },
  },
  { name    => 'SpamFilter',
    package => 'DeliveryBoy::Plugin::SpamFilter',
    payload => {
      filterset => 'standard',
      max_score => 5,
      action    => 'bounce',
    }
  },
  { name    => 'SpamFilter_2',
    package => 'DeliveryBoy::Plugin::SpamFilter',
    payload => {
      filterset => 'aggressive',
      max_score => 5,
      action    => 'tag',
    },
  },
  { name    => 'VerifyPGP',
    package => 'DeliveryBoy::Plugin::VerifyPGP',
    payload => { },
  },
  { name    => 'Deliver',
    package => 'DeliveryBoy::Plugin::Deliver',
    payload => { dest => 'Maildir' },
  },

The INI reader uses L<Config::MVP::Assembler|Config::MVP::Assembler> to build
up configuration section by section as it goes, so that's how we'll talk about
what's going on.

Every section of the config file was converted into a section in the MVP
sequence.  Each section has a unique name, which defaults to the name of the
INI section.  Each section is also associated with a package, which was
expanded from the INI section name.  The way that names are expanded can be
customized by subclassing the assembler.

Every section also has a payload -- a hashref of settings.  Note that every
entry in every payload is a simple scalar except for one.  The C<files> entry
for the Whitelist section is an arrayref.  Also, note that while it appears as
C<files> in the final output, it was given as C<file> in the input.

Config::MVP provides a mechanism by which packages can define aliases for
configuration names and an indication of what names correspond to "multi-value
parameters."  (That's part of the meaning of the name "MVP.")  When the MVP
assembler is told to start a section for C<Whitelist> it expands the section
name, loads the package, and inspects it for aliases and multivalue parameters.
Then if multiple entries for a non-multivalue parameter are given, an exception
can be raised.  Multivalue parameters are always pushed onto arrayrefs and
non-multivalue parameters are left as found.

=head2 ...so what now?

So, once our DeliveryBoy program has loaded its configuration, it needs to
initialize its plugins.  It can do something like the following:

  my $sequence = $deliveryboy->load_config;

  for my $section ($sequence->sections) {
    my $plugin = $section->package->new( $section->payload );
    $deliveryboy->add_plugin( $section->name, $plugin );
  }

That's it!  In fact, allowing this very, very block of code to load
configuration and initialize plugins is the goal of Config::MVP.

The one thing not depicted is the notion of a "root section" that you might
expect to see in an INI file.  This can be easily handled by starting your
assembler off with a pre-built section where root settings will end up.  For
more information on this, look at the docs for the specific components.

=head1 WHAT NEXT?

=head2 Making Packages work with MVP

Any package can be used as part of an MVP section.  Packages can provide some
methods to help MVP work with them.  It isn't a problem if they are not defined

=head3 mvp_aliases

This method should return a hashref of name remappings.  For example, if it
returned this hashref:

  {
    file => 'files',
    path => 'files',
  }

Then attempting to set either the "file" or "path" setting for the section
would actually set the "files" setting.

=head3 mvp_multivalue_args

This method should return a list of setting names that may have multiple values
and that will always be stored in an arrayref.

=head2 The Assembler

L<Config::MVP::Assembler|Config::MVP::Assembler> is a state machine that makes
it easy to build up your MVP-style configuration by firing off a series of
events: new section, new setting, etc.  You might want to subclass it to change
the class of sequence or section that's used or to change how section names are
expanded into packages.

=head2 Sequences and Sections

L<Config::MVP::Sequence|Config::MVP::Sequence> and
L<Config::MVP::Section|Config::MVP::Section> are the two most important classes
in MVP.  They represent the overall configuration and each section of the
configuration, respectively.  They're both fairly simple classes, and you
probably won't need to subclass them, but it's easy.

=head2 Examples in the World

For examples of Config::MVP in use, you can look at L<Dist::Zilla|Dist::Zilla>
or L<App::Addex|App::Addex>.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

