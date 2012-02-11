package Email::MIME::Kit::Role::Renderer;
BEGIN {
  $Email::MIME::Kit::Role::Renderer::VERSION = '2.102010';
}
use Moose::Role;
with 'Email::MIME::Kit::Role::Component';
# ABSTRACT: things that render templates into contents


requires 'render';

no Moose::Role;
1;

__END__
=pod

=head1 NAME

Email::MIME::Kit::Role::Renderer - things that render templates into contents

=head1 VERSION

version 2.102010

=head1 IMPLEMENTING

This role also performs L<Email::MIME::Kit::Role::Component>.

Classes implementing this role must provide a C<render> method, which is
expected to turn a template and arguments into rendered output.  The method is
used like this:

  my $output_ref = $renderer->render($input_ref, \%arg);

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

