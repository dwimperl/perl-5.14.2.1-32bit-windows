package MooseX::Getopt::ProcessedArgv;
BEGIN {
  $MooseX::Getopt::ProcessedArgv::AUTHORITY = 'cpan:STEVAN';
}
{
  $MooseX::Getopt::ProcessedArgv::VERSION = '0.39';
}
use Moose;
# ABSTRACT: MooseX::Getopt::ProcessedArgv - Class containing the results of process_argv

has 'argv_copy'          => (is => 'ro', isa => 'ArrayRef');
has 'extra_argv'         => (is => 'ro', isa => 'ArrayRef');
has 'usage'              => (is => 'ro', isa => 'Maybe[Object]');
has 'constructor_params' => (is => 'ro', isa => 'HashRef');
has 'cli_params'         => (is => 'ro', isa => 'HashRef');

no Moose;

__PACKAGE__->meta->make_immutable();

1;


__END__
=pod

=encoding utf-8

=head1 NAME

MooseX::Getopt::ProcessedArgv - MooseX::Getopt::ProcessedArgv - Class containing the results of process_argv

=head1 SYNOPSIS

  use My::App;

  my $pa = My::App->process_argv(@params);
  my $argv_copy          = $pa->argv_copy();
  my $extra_argv         = $pa->extra_argv();
  my $usage              = $pa->usage();
  my $constructor_params = $pa->constructor_params();
  my $cli_params         = $pa->cli_params();

=head1 DESCRIPTION

This object contains the result of a L<MooseX::Getopt/process_argv> call. It
contains all the information that L<MooseX::Getopt/new_with_options> uses
when calling new.

=head1 METHODS

=head2 argv_copy

Reference to a copy of the original C<@ARGV> array as it originally existed
at the time of C<new_with_options>.

=head2 extra_arg

Arrayref of leftover C<@ARGV> elements that L<Getopt::Long> did not parse.

=head2 usage

Contains the L<Getopt::Long::Descriptive::Usage> object (if
L<Getopt::Long::Descriptive> is used).

=head2 constructor_params

Parameters passed to process_argv.

=head2 cli_param

Command-line parameters parsed out of C<@ARGV>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@iinteractive.com>

=item *

Brandon L. Black <blblack@gmail.com>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=item *

Ryan D Johnson <ryan@innerfence.com>

=item *

Drew Taylor <drew@drewtaylor.com>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Ævar Arnfjörð Bjarmason <avar@cpan.org>

=item *

Chris Prather <perigrin@cpan.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Jonathan Swartz <swartz@pobox.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

