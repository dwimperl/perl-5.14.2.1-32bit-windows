package Moose::Autobox::Indexed;     
use Moose::Role 'requires';

our $VERSION = '0.11';

requires 'at';
requires 'put';
requires 'exists'; 
requires 'keys';
requires 'values'; 
requires 'kv';
requires 'slice';
requires qw(each each_key each_value each_n_values);

1;

__END__

=pod

=head1 NAME 

Moose::Autobox::Indexed - the Indexed role

=head1 DESCRIPTION

This is a role to describes an collection whose values can be 
accessed by a key of some kind. 

The role is entirely abstract, those which implement it must 
supply all it's methods. Currently both L<Moose::Autobox::Array>
and L<Moose::Autobox::Hash> implement this role.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 REQUIRED METHODS

=over 4

=item B<at>

=item B<put>

=item B<exists>

=item B<keys>

=item B<values>

=item B<kv>

=item B<slice>

=item B<each>

=item B<each_key>

=item B<each_value>

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
