package Moose::Autobox::Number;
use Moose::Role;

our $VERSION = '0.11';

with 'Moose::Autobox::Value';

sub to {
    return [ $_[0] .. $_[1] ] if $_[0] <= $_[1];
    return [ reverse $_[1] .. $_[0] ];
}

1;

__END__

=pod

=head1 NAME 

Moose::Autobox::Number - the Number role

=head1 DESCRIPTION

This is a role to describes a Numeric value. 

=head1 METHODS

=over 4

=item B<to>

Takes another number as argument and produces an array ranging from
the number the method is called on to the number given as argument. In
some situations, this method intentionally behaves different from the
range operator in perl:

  $foo = [ 5 .. 1 ]; # $foo is []

  $foo = 5->to(1);   # $foo is [ 5, 4, 3, 2, 1 ]

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
