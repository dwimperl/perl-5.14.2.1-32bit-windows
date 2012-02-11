use strict;
use warnings;
package Mixin::Linewise;
use 5.006;
our $VERSION = '0.003';
use Carp ();
Carp::confess "not meant to be loaded";

=head1 NAME

Mixin::Linewise - write your linewise code for handles; this does the rest

=head1 DESCRIPTION

It's boring to deal with opening files for IO, converting strings to
handle-like objects, and all that.  With L<Mixin::Linewise::Readers> and
L<Mixin::Linewise::Writers>, you can just write a method to handle handles, and
methods for handling strings and filenames are added for you.

=head1 BUGS

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mixin-Linewise>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Ricardo SIGNES, C<< E<lt>rjbs@cpan.orgE<gt> >>

=head1 COPYRIGHT

Copyright 2008, Ricardo SIGNES.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
