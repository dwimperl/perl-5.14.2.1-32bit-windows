use strict;
use warnings;
package Email::Simple::Creator;

our $VERSION = '2.101';

sub _crlf {
  "\x0d\x0a";
}

sub _date_header {
  require Email::Date::Format;
  Email::Date::Format::email_date();
}

sub _add_to_header {
  my ($class, $header, $key, $value) = @_;
  $value = '' unless defined $value;
  $$header .= "$key: $value" . $class->_crlf;
}

sub _finalize_header {
  my ($class, $header) = @_;
  $$header .= $class->_crlf;
}

1;

__END__

=head1 NAME

Email::Simple::Creator - private helper for building Email::Simple objects

=head1 PERL EMAIL PROJECT

This module is maintained by the Perl Email Project

L<http://emailproject.perl.org/>

=head1 AUTHORS

Casey West originally wrote Email::Simple::Creator in 2004.  Ricardo SIGNES
took over maintenance in 2006.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004 Casey West.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
