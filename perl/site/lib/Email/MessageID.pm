use strict;
use warnings;
package Email::MessageID;
use base 'Email::Address';

our $VERSION = '1.402';

=head1 NAME

Email::MessageID - Generate world unique message-ids.

=head1 SYNOPSIS

  use Email::MessageID;

  my $mid = Email::MessageID->new->in_brackets;

  print "Message-ID: $mid\x0A\x0D";

=head1 DESCRIPTION

Message-ids are optional, but highly recommended, headers that identify a
message uniquely. This software generates a unique message-id.

=head1 METHODS

=head2 new

  my $mid = Email::MessageID->new;

  my $new_mid = Email::MessageID->new( host => $myhost );

This class method constructs an L<Email::Address|Email::Address> object
containing a unique message-id. You may specify custom C<host> and C<user>
parameters.

By default, the C<host> is generated from C<Sys::Hostname::hostname>.

By default, the C<user> is generated using C<Time::HiRes>'s C<gettimeofday>
and the process ID.

Using these values we have the ability to ensure world uniqueness down to
a specific process running on a specific host, and the exact time down to
six digits of microsecond precision.

=cut

sub new {
    my ($class, %args) = @_;
    
    $args{user} ||= $class->create_user;
    $args{host} ||= $class->create_host;
        
    my $mid = join '@', @args{qw[user host]};
    
    my $addr = Email::Address->new(undef, $mid);

    bless $addr => $class;
}

=head2 create_host

  my $domain_part = Email::MessageID->create_host;

This method returns the domain part of the message-id.

=cut

my $_SYS_HOSTNAME_LONG;
sub create_host {
    unless (defined $_SYS_HOSTNAME_LONG) {
      $_SYS_HOSTNAME_LONG = (eval { require Sys::Hostname::Long; 1 }) || 0;
      require Sys::Hostname unless $_SYS_HOSTNAME_LONG;
    }

    return $_SYS_HOSTNAME_LONG ? Sys::Hostname::Long::hostname()
                               : Sys::Hostname::hostname();
}

=head2 create_user

  my $local_part = Email::MessageID->create_user;

This method returns a unique local part for the message-id.  It includes some
random data and some predictable data.

=cut

my @CHARS = ('A'..'F','a'..'f',0..9);

my $unique_value = 0;
sub _generate_string {
    my $length = 3;
    $length = rand(8) until $length > 3;
    
    join '', (map $CHARS[rand $#CHARS], 0 .. $length), $unique_value++;
}

sub create_user {
    my $pseudo_random = $_[0]->_generate_string;
    my $user = join '.', time, $pseudo_random, $$;
    return $user;
}

=head2 in_brackets

When using Email::MessageID directly to populate the C<Message-ID> field, be
sure to use C<in_brackets> to get the string inside angle brackets:


  header => [
    ...
    'Message-Id' => Email::MessageID->new->in_brackets,
  ],

Don't make this common mistake:

  header => [
    ...
    'Message-Id' => Email::MessageID->new->as_string, # WRONG!
  ],


=cut

sub in_brackets {
    my ($self) = @_;
    return sprintf '<%s>', $self->as_string;
}

1;

__END__

=pod

=head1 SEE ALSO

L<Email::Address>, L<Time::HiRes>, L<Sys::Hostname>, L<perl>.

=head1 PERL EMAIL PROJECT

This module is maintained by the Perl Email Project.

L<http://emailproject.perl.org/wiki/Email::MessageID>

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
