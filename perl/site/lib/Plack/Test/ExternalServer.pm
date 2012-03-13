use strict;
use warnings;

package Plack::Test::ExternalServer;
our $VERSION = '0.01';
# ABSTRACT: Run HTTP tests on external live servers

use URI;
use Carp;
use LWP::UserAgent;


sub test_psgi {
    my %args = @_;

    my $client = delete $args{client} or croak 'client test code needed';
    my $ua     = delete $args{ua} || LWP::UserAgent->new;
    my $base   = $ENV{PLACK_TEST_EXTERNALSERVER_URI} || delete $args{uri};
       $base   = URI->new($base) if $base;

    $client->(sub {
        my ($req) = shift->clone;

        if ($base) {
            my $uri = $req->uri->clone;
            $uri->scheme($base->scheme);
            $uri->host($base->host);
            $uri->port($base->port);
            $uri->path($base->path . $uri->path);
            $req->uri($uri);
        }

        return $ua->request($req);
    });
}

1;

__END__
=pod

=head1 NAME

Plack::Test::ExternalServer - Run HTTP tests on external live servers

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    $ PLACK_TEST_IMPL=Plack::Test::ExternalServer \
      PLACK_TEST_EXTERNALSERVER_URI=http://myhost.example/myapp/ \
      perl my_plack_test.t

=head1 DESCRIPTION

This module allows your to run your Plack::Test tests against an external
server instead of just against a local application through either mocked HTTP
or a locally spawned server.

See L<Plack::Test> on how to write tests that can use this module.

=head1 ENVIRONMENT VARIABLES

=over 4

=item PLACK_TEST_EXTERNALSERVER_URI

The value of this variable will be used as the base uri for requests to the
external server.

=back

=head1 SEE ALSO

L<Plack::Test>

L<Plack::Test::Server>

L<Plack::Test::MockHTTP>

=for Pod::Coverage test_psgi

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

