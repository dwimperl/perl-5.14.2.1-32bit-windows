package Email::MIME::Encodings;
use strict;
no strict 'refs';
use warnings;

$Email::MIME::Encodings::VERSION = "1.313";

use MIME::Base64;
use MIME::QuotedPrint;

sub identity { $_[0] }

for (qw(7bit 8bit binary)) {
    *{"encode_$_"} = *{"decode_$_"} = \&identity;
}

sub codec {
    my ($which, $how, $what) = @_;
    $how = lc $how;
    $how = "qp" if $how eq "quotedprint" or $how eq "quoted-printable";
    my $sub = __PACKAGE__->can("$which\_$how");

    unless ($sub) {
        require Carp;
        Carp::croak("Don't know how to $which $how");
    }

    # RFC2822 requires all email lines to end in CRLF. The Quoted-Printable
    # RFC requires CRLF to not be encoded, when representing newlins.  We will
    # assume, in this code, that QP is being used for plain text and not binary
    # data.  This may, someday, be wrong -- but if you are using QP to encode
    # binary data, you are already doing something bizarre.
    #
    # The only way to achieve this with MIME::QuotedPrint is to replace all
    # CRLFs with just LF and then let MIME::QuotedPrint replace all LFs with
    # CRLF. Otherwise MIME::QuotedPrint (by default) encodes CR as =0D, which
    # is against RFCs and breaks MUAs (such as Thunderbird).
    #
    # We don't modify data before Base64 encoding it because that is usually
    # binary data and modifying it at all is a bad idea. We do however specify
    # that the encoder should end lines with CRLF (since that's the email
    # standard).
    # -- rjbs and mkanat, 2009-04-16
    my $eol = "\x0d\x0a";
    if ($which eq 'encode') {
        $what =~ s/$eol/\x0a/sg if $how eq 'qp';
        return $sub->($what, $eol);
    } else {
        my $txt = $sub->($what);
        $txt =~ s/\x0a/$eol/sg if $how eq 'qp';
        return $txt;
    }
}

sub decode { return codec("decode", @_) }
sub encode { return codec("encode", @_) }

1;

=head1 NAME

Email::MIME::Encodings - A unified interface to MIME encoding and decoding

=head1 SYNOPSIS

  use Email::MIME::Encodings;
  my $encoded = Email::MIME::Encodings::encode(base64 => $body);
  my $decoded = Email::MIME::Encodings::decode(base64 => $encoded);

=head1 DESCRIPTION

This module simply wraps C<MIME::Base64> and C<MIME::QuotedPrint>
so that you can throw the contents of a C<Content-Transfer-Encoding>
header at some text and have the right thing happen.

=head1 PERL EMAIL PROJECT

This module is maintained by the Perl Email Project.

L<http://emailproject.perl.org/wiki/Email::MIME::Encodings>

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

C<MIME::Base64>, C<MIME::QuotedPrint>, C<Email::MIME>.

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Casey West F<<casey@geeknest.com>>.

Copyright 2003 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
