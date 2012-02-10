package Parse::ErrorString::Perl::StackItem;
BEGIN {
  $Parse::ErrorString::Perl::StackItem::VERSION = '0.15';
}

#ABSTRACT: a Perl stack item object

use strict;
use warnings;

sub new {
	my ( $class, $self ) = @_;
	bless $self, ref $class || $class;
	return $self;
}

use Class::XSAccessor getters => {
	sub          => 'sub',
	file         => 'file',
	file_abspath => 'file_abspath',
	file_msgpath => 'file_msgpath',
	line         => 'line',
};

1;



=pod

=head1 NAME

Parse::ErrorString::Perl::StackItem - a Perl stack item object

=head1 VERSION

version 0.15

=head1 Parse::ErrorString::Perl::StackItem

=over

=item sub

The subroutine that was called, qualified with a package name (as
printed by C<use diagnostics>).

=item file

File where subroutine was called. See C<file> in
C<Parse::ErrorString::Perl::ErrorItem>.

=item file_abspath

See C<file_abspath> in C<Parse::ErrorString::Perl::ErrorItem>.

=item file_msgpath

See C<file_msgpath> in C<Parse::ErrorString::Perl::ErrorItem>.

=item line

The line where the subroutine was called.

=back

=head1 AUTHORS

=over 4

=item *

Petar Shangov, C<< <pshangov at yahoo.com> >>

=item *

Gabor Szabo L<http://szabgab.com/>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Petar Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

