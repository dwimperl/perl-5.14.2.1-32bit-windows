package Dist::Zilla::Plugin::GenerateFile;
{
  $Dist::Zilla::Plugin::GenerateFile::VERSION = '4.300007';
}
# ABSTRACT: build a custom file from only the plugin configuration
use Moose;
use Moose::Autobox;
with (
  'Dist::Zilla::Role::FileGatherer',
  'Dist::Zilla::Role::TextTemplate',
);

use namespace::autoclean;

use Dist::Zilla::File::InMemory;


sub mvp_multivalue_args { qw(content) }


has filename => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);


has content => (
  is  => 'ro',
  isa => 'ArrayRef',
);


has is_template => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub gather_files {
  my ($self, $arg) = @_;

  my $content = join "\n", $self->content->flatten;
  $content .= qq{\n};

  if ($self->is_template) {
    $content = $self->fill_in_string(
      $content,
      {
        dist   => \($self->zilla),
        plugin => \($self),
      },
    );
  }

  my $file = Dist::Zilla::File::InMemory->new({
    name    => $self->filename,
    content => $content,
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::GenerateFile - build a custom file from only the plugin configuration

=head1 VERSION

version 4.300007

=head1 SYNOPSIS

In your F<dist.ini>:

  [GenerateFile]
  filename    = todo/master-plan.txt
  is_template = 1
  content = # Outlines the plan for world domination by {{$dist->name}}
  content =
  content = Item 1: Think of an idea!
  content = Item 2: ?
  content = Item 3: Profit!

=head1 DESCRIPTION

This plugin adds a file to the distribution.

You can specify the content, as a sequence of lines, in your configuration.
The specified content might be literal, or might be a Text::Template template.

=head2 Templating of the content

If you provide a C<is_template> parameter of "1", The content will also be run
through Text::Template.  The variables C<$plugin> and C<$dist> will be
provided, set to the GenerateFile plugin and the Dist::Zilla object
respectively.

=head1 ATTRIBUTES

=head2 filename

This attribute names the file you want to generate.  It is required.

=head2 content

The C<content> attribute is an arrayref of lines that will be joined together
with newlines to form the file content.

=head2 is_template

This attribute is a bool indicating whether or not the content should be
treated as a Text::Template template.  By default, it is false.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

