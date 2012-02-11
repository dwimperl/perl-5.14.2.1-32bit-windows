package Config::MVP::Reader::Findable;
BEGIN {
  $Config::MVP::Reader::Findable::VERSION = '2.200001';
}
use Moose::Role;
# ABSTRACT: a config class that Config::MVP::Reader::Finder can find


requires 'refined_location';

no Moose::Role;
1;


__END__
=pod

=head1 NAME

Config::MVP::Reader::Findable - a config class that Config::MVP::Reader::Finder can find

=head1 VERSION

version 2.200001

=head1 DESCRIPTION

Config::MVP::Reader::Findable is a role meant to be composed alongside
Config::MVP::Reader.

=head1 METHODS

=head2 refined_location

This method is used to decide whether a Findable reader can read a specific
thing under the C<$location> argument passed to C<read_config>.  The location
could be a directory or base file name or dbh or almost anything else.  This
method will return false if it can't find anything to read.  If it can find
something to read, it will return a new (or unchanged) value for C<$location>
to be used in reading the config.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

