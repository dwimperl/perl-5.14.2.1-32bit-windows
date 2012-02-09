package Test::Trap::Builder::TempFile;

use version; $VERSION = qv('0.2.1');

use strict;
use warnings;
use IO::Handle;
use File::Temp qw( tempfile );
use Test::Trap::Builder;

sub import {
  Test::Trap::Builder->output_layer_backend( tempfile => $_ ) for sub {
    my $self = shift;
    my ($name, $fileno, $globref) = @_;
    my $pid = $$;
    my ($fh, $file) = tempfile( UNLINK => 1 ); # XXX: Test?
    $self->Teardown($_) for sub {
      # if the file is opened by some other process, that one should deal with it:
      return unless $pid == $$;
      local $/;
      $self->{$name} .= <$fh>;
      close $fh;
    };
    binmode $fh; # superfluos?
    local *$globref;
    {
      no warnings 'io';
      open *$globref, '>>', $file;
    }
    binmode *$globref; # must write as we read.
    *$globref->autoflush(1);
    $self->Next;
  };
}

1; # End of Test::Trap::Builder::TempFile

__END__

=head1 NAME

Test::Trap::Builder::TempFile - Output layer backend using File::Temp

=head1 VERSION

Version 0.2.1

=head1 DESCRIPTION

This module provides an implementation I<tempfile>, based on
File::Temp, for the trap's output layers.  Note that you may specify
different implementations for each output layer on the trap.

See also L<Test::Trap> (:stdout and :stderr) and
L<Test::Trap::Builder> (output_layer).

=head1 CAVEATS

Using File::Temp, we need privileges to create tempfiles.

We need disk space for the output of every trap (it should clean up
after the trap is sprung).

Disk access may be slow -- certainly compared to the in-memory files
of PerlIO.

Threads?  No idea.  It might even work correctly.

=head1 BUGS

Please report any bugs or feature requests directly to the author.

=head1 AUTHOR

Eirik Berg Hanssen, C<< <ebhanssen@allverden.no> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Eirik Berg Hanssen, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
