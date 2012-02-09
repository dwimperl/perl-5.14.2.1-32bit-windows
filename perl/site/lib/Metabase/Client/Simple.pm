# 
# This file is part of Metabase-Client-Simple
# 
# This software is Copyright (c) 2010 by David Golden.
# 
# This is free software, licensed under:
# 
#   The Apache License, Version 2.0, January 2004
# 
use 5.006;
use strict;
use warnings;

package Metabase::Client::Simple;
BEGIN {
  $Metabase::Client::Simple::VERSION = '0.008';
}
# ABSTRACT: a client that submits to Metabase servers

use HTTP::Status qw/:constants/;
use HTTP::Request::Common ();
use JSON 2 ();
use LWP::UserAgent 5.54 (); # keep_alive
use URI;

my @valid_args;
BEGIN {
  @valid_args = qw(profile secret uri);

  for my $arg (@valid_args) {
    no strict 'refs';
    *$arg = sub { $_[0]->{$arg}; }
  }
}


sub new {
  my ($class, @args) = @_;

  my $args = $class->__validate_args(
    \@args,
    { map { $_ => 1 } @valid_args }
  );

  # uri must have a trailing slash
  $args->{uri} .= "/" unless substr($args->{uri}, -1) eq '/';

  my $self = bless $args => $class;

  unless ( $self->profile->isa('Metabase::User::Profile') ) {
    Carp::confess( "'profile' argument for $class must be a Metabase::User::Profile" );
  }
  unless ( $self->secret->isa('Metabase::User::Secret') ) {
    Carp::confess( "'profile' argument for $class must be a Metabase::User::secret" );
  }

  my $scheme = URI->new( $self->uri )->scheme;
  unless ( $self->_ua->is_protocol_supported( $scheme ) ) {
    my $msg = "Scheme '$scheme' is not supported by your LWP::UserAgent.\n";
    if ( $scheme eq 'https' ) {
      $msg .= "You must install Crypt::SSLeay or IO::Socket::SSL or use http instead.\n";
    }
    die $msg;
  }

  return $self;
}

sub _ua {
  my ($self) = @_;
  if ( ! $self->{_ua} ) {
    $self->{_ua} = LWP::UserAgent->new(
      agent => __PACKAGE__ . "/" . __PACKAGE__->VERSION . " ",
      env_proxy => 1,
      keep_alive => 5,
    );
  }
  return $self->{_ua};
}


sub submit_fact {
  my ($self, $fact) = @_;

  my $path = sprintf 'submit/%s', $fact->type;

  $fact->set_creator($self->profile->resource)
    unless $fact->creator;

  my $req_uri = $self->_abs_uri($path);

  my $req = HTTP::Request::Common::POST(
    $req_uri,
    Content_Type => 'application/json',
    Accept       => 'application/json',
    Content      => JSON->new->ascii->encode($fact->as_struct),
  );
  $req->authorization_basic($self->profile->resource->guid, $self->secret->content);

  my $res = $self->_ua->request($req);

  if ($res->code == HTTP_UNAUTHORIZED) {
    if ( $self->guid_exists( $self->profile->guid ) ) {
      Carp::confess $self->_error( $res => "authentication failed" );
    }
    $self->register; # dies on failure
    # should now be registered so try again
    $res = $self->_ua->request($req);
  }

  unless ( $res->is_success ) {
    Carp::confess $self->_error( $res => "fact submission failed" );
  }

  # This wil be something more informational later, like "accepted" or
  # "queued," maybe. -- rjbs, 2009-03-30
  return 1;
}


sub guid_exists {
  my ($self, $guid) = @_;

  my $path = sprintf 'guid/%s', $guid;

  my $req_uri = $self->_abs_uri($path);

  my $req = HTTP::Request::Common::HEAD( $req_uri );

  my $res = $self->_ua->request($req);

  return $res->is_success ? 1 : 0;
}


sub register {
  my ($self) = @_;

  my $req_uri = $self->_abs_uri('register');

  for my $type ( qw/profile secret/ ) {
    $self->$type->set_creator( $self->$type->resource)
      unless $self->$type->creator;
  }

  my $req = HTTP::Request::Common::POST(
    $req_uri,
    Content_Type => 'application/json',
    Accept       => 'application/json',
    Content      => JSON->new->ascii->encode([
      $self->profile->as_struct, $self->secret->as_struct
    ]),
  );

  my $res = $self->_ua->request($req);

  unless ($res->is_success) {
    Carp::confess $self->_error( $res => "registration failed" );
  }

  return 1;
}

#--------------------------------------------------------------------------#
# private methods
#--------------------------------------------------------------------------#

# Stolen from ::Fact.
# XXX: Should refactor this into something in Fact, which we can then rely on.
# -- rjbs, 2009-03-30
sub __validate_args {
  my ($self, $args, $spec) = @_;
  my $hash = (@$args == 1 and ref $args->[0]) ? { %{ $args->[0]  } }
           : (@$args == 0)                    ? { }
           :                                    { @$args };

  my @errors;

  for my $key (keys %$hash) {
    push @errors, qq{unknown argument "$key" when constructing $self}
      unless exists $spec->{ $key };
  }

  for my $key (grep { $spec->{ $_ } } keys %$spec) {
    push @errors, qq{missing required argument "$key" when constructing $self}
      unless defined $hash->{ $key };
  }

  Carp::confess(join qq{\n}, @errors) if @errors;

  return $hash;
}

sub _abs_uri {
  my ($self, $str) = @_;
  my $req_uri = URI->new($str)->abs($self->uri);
}

sub _error {
  my ($self, $res, $prefix) = @_;
  $prefix ||= "unrecognized error";
  if ( ref($res) && $res->header('Content-Type') eq 'application/json') {
    my $entity = JSON->new->ascii->decode($res->content);
    return "$prefix\: $entity->{error}";
  } else {
    return "$prefix\: " . $res->message;
  }
}

1;



=pod

=head1 NAME

Metabase::Client::Simple - a client that submits to Metabase servers

=head1 VERSION

version 0.008

=head1 SYNOPSIS

  use Metabase::Client::Simple;
  use Metabase::User::Profile;
  use Metabase::User::Secret;

  my $profile = Metabase::User::Profile->load('user.profile.json');
  my $secret  = Metabase::User::Secret ->load('user.secret.json' );

  my $client = Metabase::Client::Simple->new({
    profile => $profile,
    secret  => $secret,
    uri     => 'http://metabase.example.com/',
  });

  my $fact = generate_metabase_fact;

  $client->submit_fact($fact);

=head1 DESCRIPTION

Metabase::Client::Simple provides is extremely simple, lightweight library for
submitting facts to a L<Metabase|Metabase> web server.

=head1 METHODS

=head2 new

  my $client = Metabase::Client::Simple->new(\%arg)

This is the object constructor.

Valid arguments are:

  profile - a Metabase::User::Profile object
  secret  - a Metabase::User::Secret object
  uri     - the root URI for the metabase server

If you use a C<uri> argument with the 'https' scheme, you must have
Crypt::SSLeay or IO::Socket::SSL installed.

=head2 submit_fact

  $client->submit_fact($fact);

This method will submit a L<Metabase::Fact|Metabase::Fact> object to the
client's server.  On success, it will return a true value.  On failure, it will
raise an exception.

=head2 guid_exists

  $client->guid_exists('2f8519c6-24cf-11df-90b1-0018f34ec37c');

This method will check whether the given GUID is found on the metabase server.
The GUID must be in lower-case, string form.  It will return true or false.
Note that a server error will also result in a false value.

=head2 register

  $client->register;

This method will submit the user credentials to the metabase server.  It will
be called automatically by C<submit_fact> if necessary.   You generally won't
need to use it.  On success, it will return a true value.  On failure, it will
raise an exception.

=for Pod::Coverage profile secret uri

=head1 AUTHORS

  David Golden <dagolden@cpan.org>
  Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__



