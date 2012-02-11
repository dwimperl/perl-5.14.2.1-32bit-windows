package Dist::Zilla::Plugin::Manifest;
{
  $Dist::Zilla::Plugin::Manifest::VERSION = '4.300007';
}
# ABSTRACT: build a MANIFEST file
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;

use Dist::Zilla::File::FromCode;


sub __fix_filename {
  my ($name) = @_;
  return $name unless $name =~ /[ '\\]/;
  $name =~ s/\\/\\\\/g;
  $name =~ s/'/\\'/g;
  return qq{'$name'};
}

sub gather_files {
  my ($self, $arg) = @_;

  my $zilla = $self->zilla;

  my $file = Dist::Zilla::File::FromCode->new({
    name => 'MANIFEST',
    code => sub {
      $zilla->files->map(sub { $_->name })
            ->sort->map( sub { __fix_filename($_) } )->join("\n")
      . "\n",
    },
  });

  $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::Manifest - build a MANIFEST file

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

If included, this plugin will produce a F<MANIFEST> file for the distribution,
listing all of the files it contains.  For obvious reasons, it should be
included as close to last as possible.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

