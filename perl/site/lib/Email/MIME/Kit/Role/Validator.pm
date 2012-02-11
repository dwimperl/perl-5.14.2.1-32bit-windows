package Email::MIME::Kit::Role::Validator;
BEGIN {
  $Email::MIME::Kit::Role::Validator::VERSION = '2.102010';
}
use Moose::Role;
# ABSTRACT: things that validate assembly parameters


with 'Email::MIME::Kit::Role::Component';

requires 'validate';

no Moose::Role;
1;

__END__
=pod

=head1 NAME

Email::MIME::Kit::Role::Validator - things that validate assembly parameters

=head1 VERSION

version 2.102010

=head1 IMPLEMENTING

This role also performs L<Email::MIME::Kit::Role::Component>.

Classes implementing this role are used to validate that the arguments passed
to C<< $mkit->assemble >> are valid.  Classes must provide a C<validate> method
which will be called with the hashref of values passed to the kit's C<assemble>
method.  If the arguments are not valid for the kit, the C<validate> method
should raise an exception.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

