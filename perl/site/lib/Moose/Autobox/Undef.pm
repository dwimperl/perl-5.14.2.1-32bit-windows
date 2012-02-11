package Moose::Autobox::Undef;
use Moose::Role 'with';

our $VERSION = '0.11';

with 'Moose::Autobox::Item';
            
sub defined { 0 }

1;

__END__

=pod

=head1 NAME 

Moose::Autobox::Undef - the Undef role

=head1 SYNOPOSIS

  use Moose::Autobox;

  my $x;
  $x->defined; # false

=head1 DESCRIPTION

This is a role to describes a undefined value. 

=head1 METHODS

=over 4

=item B<defined>

=back

=over 4

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
