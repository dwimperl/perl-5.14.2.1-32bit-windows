package Dist::Zilla::Plugin::GatherDir::Template;
{
  $Dist::Zilla::Plugin::GatherDir::Template::VERSION = '4.300007';
}
# ABSTRACT: gather all the files in a directory and use them as templates
use Moose;
extends 'Dist::Zilla::Plugin::GatherDir';
with 'Dist::Zilla::Role::TextTemplate';

use namespace::autoclean;

use autodie;
use Moose::Autobox;
use Dist::Zilla::File::FromCode;


sub _file_from_filename {
  my ($self, $filename) = @_;

  my $template = do {
    open my $fh, '<', $filename;
    local $/;
    <$fh>;
  };

  return Dist::Zilla::File::FromCode->new({
    name => $filename,
    mode => ((stat $filename)[2] & 0755) | 0200, # kill world-writeability, make sure owner-writable.
    code => sub {
      my ($file_obj) = @_;
      $self->fill_in_string(
        $template,
        {
          dist   => \($self->zilla),
          plugin => \($self),
        },
      );
    },
  });
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::GatherDir::Template - gather all the files in a directory and use them as templates

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This is a very, very simple L<FileGatherer|Dist::Zilla::FileGatherer> plugin.
It looks in the directory named in the L</root> attribute and adds all the
files it finds there.  If the root begins with a tilde, the tilde is replaced
with the current user's home directory according to L<File::HomeDir>.

It is meant to be used when minting dists with C<dzil new>, but could be used
in building existing dists, too.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

