## no critic (PodSections,UseWarnings,Interpolation,EndWithOne,NoisyQuotes)

package B::Keywords;

use strict;

require Exporter;
*import = *import = \&Exporter::import;

use vars qw( @EXPORT_OK %EXPORT_TAGS );
@EXPORT_OK = qw( @Scalars @Arrays @Hashes @Filehandles @Symbols
                 @Functions @Barewords );
%EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

use vars '$VERSION';
$VERSION = '1.12';

use vars '@Scalars';
@Scalars = (
    qw( $a
        $b
        $_ $ARG
        $& $MATCH
        $` $PREMATCH
        $' $POSTMATCH
        $+ $LAST_PAREN_MATCH
        $* $MULTILINE_MATCHING
        $. $INPUT_LINE_NUMBER $NR
        $/ $INPUT_RECORD_SEPARATOR $RS
        $| $OUTPUT_AUTO_FLUSH ), '$,', qw( $OUTPUT_FIELD_SEPARATOR $OFS
        $\ $OUTPUT_RECORD_SEPARATOR $ORS
        $" $LIST_SEPARATOR
        $; $SUBSCRIPT_SEPARATOR $SUBSEP
        ), '$#', qw( $OFMT
        $% $FORMAT_PAGE_NUMBER
        $= $FORMAT_LINES_PER_PAGE
        $- $FORMAT_LINES_LEFT
        $~ $FORMAT_NAME
        $^ $FORMAT_TOP_NAME
        $: $FORMAT_LINE_BREAK_CHARACTERS
        $? $CHILD_ERROR $^CHILD_ERROR_NATIVE
        $! $ERRNO $OS_ERROR
        $@ $EVAL_ERROR
        $$ $PROCESS_ID $PID
        $< $REAL_USER_ID $UID
        $> $EFFECTIVE_USER_ID $EUID ), '$(', qw( $REAL_GROUP_ID $GID ), '$)',
    qw(
        $EFFECTIVE_GROUP_ID $EGID
        $0 $PROGRAM_NAME
        $[
        $]
        $^A $ACCUMULATOR
        $^C $COMPILING
        $^D $DEBUGGING
        $^E $EXTENDED_OS_ERROR
        $^ENCODING
        $^F $SYSTEM_FD_MAX
        $^H
        $^I $INPLACE_EDIT
        $^L $FORMAT_FORMFEED
        $^M
        $^N
        $^O $OSNAME
        $^OPEN
        $^P $PERLDB
        $^R $LAST_REGEXP_CODE_RESULT
        $^RE_DEBUG_FLAGS
        $^RE_TRIE_MAXBUF
        $^S $EXCEPTIONS_BEING_CAUGHT
        $^T $BASETIME
        $^TAINT
        $^UNICODE
        $^UTF8LOCALE
        $^V $PERL_VERSION
        $^W $WARNING $^WARNING_BITS
        $^WIDE_SYSTEM_CALLS
        $^X $EXECUTABLE_NAME
        $ARGV
        ),
);

use vars '@Arrays';
@Arrays = qw(
    @+ $LAST_MATCH_END
    @- @LAST_MATCH_START
    @ARGV
    @INC
    @_
);

use vars '@Hashes';
@Hashes = qw(
    %OVERLOAD
    %!
    %^H
    %INC
    %ENV
    %SIG
);

use vars '@Filehandles';
@Filehandles = qw(
    *ARGV ARGV
    ARGVOUT
    STDIN
    STDOUT
    STDERR
);

use vars '@Functions';
@Functions = qw(
    __SUB__
    AUTOLOAD
    BEGIN
    DESTROY
    END
    INIT
    CHECK
    UNITCHECK
    abs
    accept
    alarm
    atan2
    bind
    binmode
    bless
    break
    caller
    chdir
    chmod
    chomp
    chop
    chown
    chr
    chroot
    close
    closedir
    connect
    cos
    crypt
    dbmclose
    dbmopen
    defined
    delete
    die
    dump
    each
    endgrent
    endhostent
    endnetent
    endprotoent
    endpwent
    endservent
    eof
    eval
    evalbytes
    exec
    exists
    exit
    fc
    fcntl
    fileno
    flock
    fork
    format
    formline
    getc
    getgrent
    getgrgid
    getgrnam
    gethostbyaddr
    gethostbyname
    gethostent
    getlogin
    getnetbyaddr
    getnetbyname
    getnetent
    getpeername
    getpgrp
    getppid
    getpriority
    getprotobyname
    getprotobynumber
    getprotoent
    getpwent
    getpwnam
    getpwuid
    getservbyname
    getservbyport
    getservent
    getsockname
    getsockopt
    glob
    gmtime
    goto
    grep
    hex
    index
    int
    ioctl
    join
    keys
    kill
    last
    lc
    lcfirst
    length
    link
    listen
    local
    localtime
    log
    lstat
    map
    mkdir
    msgctl
    msgget
    msgrcv
    msgsnd
    my
    next
    not
    oct
    open
    opendir
    ord
    our
    pack
    pipe
    pop
    pos
    print
    printf
    prototype
    push
    quotemeta
    rand
    read
    readdir
    readline
    readlink
    readpipe
    recv
    redo
    ref
    rename
    require
    reset
    return
    reverse
    rewinddir
    rindex
    rmdir
    say
    scalar
    seek
    seekdir
    select
    semctl
    semget
    semop
    send
    setgrent
    sethostent
    setnetent
    setpgrp
    setpriority
    setprotoent
    setpwent
    setservent
    setsockopt
    shift
    shmctl
    shmget
    shmread
    shmwrite
    shutdown
    sin
    sleep
    socket
    socketpair
    sort
    splice
    split
    sprintf
    sqrt
    srand
    stat
    state
    study
    substr
    symlink
    syscall
    sysopen
    sysread
    sysseek
    system
    syswrite
    tell
    telldir
    tie
    tied
    time
    times
    truncate
    uc
    ucfirst
    umask
    undef
    unlink
    unpack
    unshift
    untie
    use
    utime
    values
    vec
    wait
    waitpid
    wantarray
    warn
    write

    -r -w -x -o
    -R -W -X -O -e -z -s
    -f -d -l -p -S -b -c -t
    -u -g -k
    -T -B
    -M -A -C
);

use vars '@Barewords';
@Barewords = qw(
    __FILE__
    __LINE__
    __PACKAGE__
    __DATA__
    __END__
    CORE
    EQ
    GE
    GT
    LE
    LT
    NE
    NULL
    and
    cmp
    continue
    default
    do
    else
    elsif
    eq
    err
    exp
    for
    foreach
    ge
    given
    gt
    if
    le
    lock
    lt
    m
    ne
    no
    or
    package
    q
    qq
    qr
    qw
    qx
    s
    sub
    tr
    unless
    until
    when
    while
    x
    xor
    y
);

use vars '@Symbols';
@Symbols = ( @Scalars, @Arrays, @Hashes, @Filehandles, @Functions );

# This quote is blatantly copied from ErrantStory.com, Michael Poe's
# comic.
BEGIN { $^W = 0 }
"You know, when you stop and think about it, Cthulhu is a bit a Mary Sue isn't he?"

__END__

=head1 NAME

B::Keywords - Lists of reserved barewords and symbol names

=head1 SYNOPSIS

  use B::Keywords qw( @Symbols @Barewords );
  print join "\n", @Symbols,
                   @Barewords;

=head1 DESCRIPTION

C<B::Keywords> supplies seven arrays of keywords: C<@Scalars>,
C<@Arrays>, C<@Hashes>, C<@Filehandles>, C<@Symbols>, C<@Functions>,
and C<@Barewords>. The C<@Symbols> array includes the contents of each
of C<@Scalars>, C<@Arrays>, C<@Hashes>, C<@Functions> and C<@Filehandles>.
Similarly, C<@Barewords> adds a few non-function keywords and
operators to the C<@Functions> array.

All additions and modifications are welcome.

=head1 DATA

=over

=item C<@Scalars>

=item C<@Arrays>

=item C<@Hashes>

=item C<@Filehandles>

=item C<@Functions>

The above are lists of variables, special file handles, and built in
functions.

=item C<@Symbols>

This is just the combination of all of the above: variables, file
handles, and functions.

=item C<@Barewords>

This is a list of other special keywords in perl including operators
and all the control structures.

=back

=head1 EXPORT

Anything can be exported if you desire. Use the :all tag to get
everything.

=head1 SEE ALSO

keywords.pl from the perl source, L<perlvar>, L<perlfunc>,
L<perldelta>.



=head1 BUGS

Please report any bugs or feature requests to C<bug-B-Keywords at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=B-Keywords>. I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc B::Keywords

You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=B-Keywords>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/B-Keywords>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/B-Keywords>

=item * Search CPAN

L<http://search.cpan.org/dist/B-Keywords>

=back

=head1 ACKNOWLEDGEMENTS

Michael G Schwern for patches

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Joshua ben Jore, All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software
   Foundation; version 2, or

b) the "Artistic License" which comes with Perl.

=head1 SOURCE AVAILABILITY

This source is in Github: L<git://github.com/jbenjore/b-keywords.git>

=head1 AUTHOR

Joshua ben Jore <jjore@cpan.org>
