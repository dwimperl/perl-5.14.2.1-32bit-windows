package Email::Sender::Success;
{
  $Email::Sender::Success::VERSION = '0.110003';
}
use Moose;
# ABSTRACT: the result of successfully sending mail


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Email::Sender::Success - the result of successfully sending mail

=head1 VERSION

version 0.110003

=head1 DESCRIPTION

An Email::Sender::Success object is just an indicator that an email message was
successfully sent.  Unless extended, it has no properties of its own.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

