use strict;
use warnings;
package Software::License::None;
{
  $Software::License::None::VERSION = '0.103004';
}
use base 'Software::License';
# ABSTRACT: describes a "license" that gives no license for re-use

sub name      { q("No License" License) }
sub url       { undef }

sub meta_name  { 'restrictive' }
sub meta2_name { 'restricted'  }

1;


=pod

=head1 NAME

Software::License::None - describes a "license" that gives no license for re-use

=head1 VERSION

version 0.103004

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__DATA__
__NOTICE__
This software is copyright (c) {{$self->year}} by {{$self->holder}}.  No
license is granted to other entities.
__LICENSE__
All rights reserved.
