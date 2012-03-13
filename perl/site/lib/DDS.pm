#This all has to be one line for MakeMaker version scanning.
use Data::Dump::Streamer (); BEGIN{ *DDS:: = \%Data::Dump::Streamer:: } $VERSION=$DDS::VERSION;
1;

=head1 NAME

DDS - Alias for Data::Dump::Streamer

=head1 SYNOPSIS

  perl -MDDS -e "Dump \%INC"

=head1 DESCRIPTION

See L<Data::Dump::Streamer>.

=head1 VERSION

 $Id: Makefile.PL 30 2006-04-16 15:33:25Z demerphq $

=cut

