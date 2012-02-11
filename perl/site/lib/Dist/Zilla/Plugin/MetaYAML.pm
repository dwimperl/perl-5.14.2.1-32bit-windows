package Dist::Zilla::Plugin::MetaYAML;
{
  $Dist::Zilla::Plugin::MetaYAML::VERSION = '4.300007';
}
# ABSTRACT: produce a META.yml
use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;

use CPAN::Meta::Converter 2.101550; # improved downconversion
use CPAN::Meta::Validator 2.101550; # improved downconversion
use Hash::Merge::Simple ();


has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'META.yml',
);


has version => (
  is  => 'ro',
  isa => 'Num',
  default => '1.4',
);

sub gather_files {
  my ($self, $arg) = @_;

  require Dist::Zilla::File::FromCode;
  require YAML::Tiny;

  my $zilla = $self->zilla;

  my $file  = Dist::Zilla::File::FromCode->new({
    name => $self->filename,
    code => sub {
      my $distmeta  = $zilla->distmeta;

      my $validator = CPAN::Meta::Validator->new($distmeta);

      unless ($validator->is_valid) {
        my $msg = "Invalid META structure.  Errors found:\n";
        $msg .= join( "\n", $validator->errors );
        $self->log_fatal($msg);
      }

      my $converter = CPAN::Meta::Converter->new($distmeta);
      my $output    = $converter->convert(version => $self->version);

      YAML::Tiny::Dump($output);
    },
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::MetaYAML - produce a META.yml

=head1 VERSION

version 4.300007

=head1 DESCRIPTION

This plugin will add a F<META.yml> file to the distribution.

For more information on this file, see L<Module::Build::API> and L<CPAN::Meta>.

=head1 ATTRIBUTES

=head2 filename

If given, parameter allows you to specify an alternate name for the generated
file.  It defaults, of course, to F<META.yml>.

=head2 version

This parameter lets you pick what version of the spec to use when generating
the output.  It defaults to 1.4, the most commonly supported version at
present.

B<This may change without notice in the future.>

Once version 2 of the META file spec is more widely supported, this may default
to 2.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

