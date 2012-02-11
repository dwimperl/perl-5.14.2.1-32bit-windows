use strict;
use warnings;

package Perl::PrereqScanner::Scanner;
{
  $Perl::PrereqScanner::Scanner::VERSION = '1.009';
}
use Moose::Role;
# ABSTRACT: something that scans for prereqs in a Perl document


requires 'scan_for_prereqs';

# DO NOT RELY ON THIS EXISTING OUTSIDE OF CORE!
# THIS MIGHT GO AWAY WITHOUT NOTICE!
# -- rjbs, 2010-04-06
sub _q_contents {
  my ($self, $token) = @_;
  my @contents;
  if ( $token->isa('PPI::Token::QuoteLike::Words') || $token->isa('PPI::Token::Number') ) {
    @contents = $token->literal;
  } else {
    @contents = $token->string;
  }

  return @contents;
}

1;

__END__
=pod

=head1 NAME

Perl::PrereqScanner::Scanner - something that scans for prereqs in a Perl document

=head1 VERSION

version 1.009

=head1 DESCRIPTION

This is a role to be composed into classes that will act as scanners plugged
into a Perl::PrereqScanner object.

These classes must provide a C<scan_for_prereqs> method, which will be called
like this:

  $scanner->scan_for_prereqs($ppi_doc, $version_requirements);

The scanner should alter alter the L<CPAN::Meta::Requirements> object to reflect
its findings about the PPI document.

=head1 AUTHORS

=over 4

=item *

Jerome Quelin

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

