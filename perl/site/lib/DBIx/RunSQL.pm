package DBIx::RunSQL;
use strict;
use DBI;

use vars qw($VERSION);
$VERSION = '0.07';

=head1 NAME

DBIx::RunSQL - run SQL to create a database schema

=cut

=head1 SYNOPSIS

    #!/usr/bin/perl -w
    use strict;
    use lib 'lib';
    use DBIx::RunSQL;

    my $test_dbh = DBIx::RunSQL->create(
        dsn     => 'dbi:SQLite:dbname=:memory:',
        sql     => 'sql/create.sql',
        force   => 1,
        verbose => 1,
    );
    
    ... # run your tests with a DB setup fresh from setup.sql

=head1 METHODS

=head2 C<< DBIx::RunSQL->create ARGS >>

Creates the database and returns the database handle

=over 4

=item *

C<sql> - name of the file containing the SQL statements

The default is C<sql/create.sql>

If C<sql> is a reference to a glob or a filehandle,
the SQL will be read from that. B<not implemented>

If C<sql> is undefined, the C<$::DATA> or the C<0> filehandle will
be read until exhaustion.  B<not implemented>

This allows to create SQL-as-programs as follows:

  #!/usr/bin/perl -w -MDBIx::RunSQL=create
  create table ...

=item *

C<dsn>, C<user>, C<password> - DBI parameters for connecting to the DB

=item *

C<dbh> - a premade database handle to be used instead of C<dsn>

=item *

C<force> - continue even if errors are encountered

=item *

C<verbose> - print each SQL statement as it is run

=item *

C<verbose_handler> - callback to call with each SQL statement instead of C<print>

=item *

C<verbose_fh> - filehandle to write to instead of C<STDOUT>

=back

=cut

sub create {
    my ($self,%args) = @_;

    $args{sql} ||= 'sql/create.sql';

    my $dbh = delete $args{ dbh };
    if (! $dbh) {
        $dbh = DBI->connect($args{dsn}, $args{user}, $args{password}, {})
            or die "Couldn't connect to DSN '$args{dsn}' : " . DBI->errstr;
    };
    
    if (! $args{ verbose_handler }) {
        $args{ verbose_fh } ||= \*main::STDOUT;
        $args{ verbose_handler } = sub {
            print { $args{ verbose_fh } } "$_[0]\n";
        };
    };

    $self->run_sql_file(
        dbh => $dbh,
        %args,
    );

    $dbh
};

=head2 C<< DBIx::RunSQL->run_sql_file ARGS >>

    my $dbh = DBI->connect(...)
    
    for my $file (sort glob '*.sql') {
        DBIx::RunSQL->run_sql_file(
            verbose => 1,
            dbh     => $dbh,
            sql     => $file,
        );
    };

Runs an SQL file on a prepared database handle.

=over 4

=item *

C<dbh> - a premade database handle

=item *

C<sql> - name of the file containing the SQL statements

=item *

C<force> - continue even if errors are encountered

=item *

C<verbose> - print each SQL statement as it is run

=item *

C<verbose_handler> - callback to call with each SQL statement instead of C<print>

=item *

C<verbose_fh> - filehandle to write to instead of C<STDOUT>

=back

=cut

sub run_sql_file {
    my ($class,%args) = @_;
    my $errors = 0;
    my @sql;
    {
        open my $fh, "<", $args{sql}
            or die "Couldn't read '$args{sql}' : $!";
        local $/;
        @sql = split /;\n/, <$fh> # potentially this should become C<< $/ = ";\n"; >>
        # and a while loop to handle large SQL files
    };
    
    $args{ verbose_handler } ||= sub {
        if ($args{ verbose }) {
            $args{ verbose_fh } ||= \*main::STDOUT;
            print { $args{ verbose_fh } } "--\n$_[0]\n";
        };
    };
    my $status = delete $args{ verbose_handler };

    for my $statement (@sql) {
        $statement =~ s/^\s*--.*$//mg;
        next unless $statement =~ /\S/; # skip empty lines
        
        $status->($statement);
        if (! $args{dbh}->do($statement)) {
            $errors++;
            if (!$args{force}) {
                die "[SQL ERROR]: $statement\n";
            } else {
                warn "[SQL ERROR]: $statement\n";
            };
        };
    };
    $errors
}

sub parse_command_line {
    my ($package,$appname,@argv) =  @_;
    require Getopt::Long; Getopt::Long->import();
    require Pod::Usage; Pod::Usage->import();
    
    if (! @argv) { @argv = @ARGV };
    
    local @ARGV = @argv;
    if (GetOptions(
        'user:s' => \my $user,
        'password:s' => \my $password,
        'dsn:s' => \my $dsn,
        'verbose' => \my $verbose,
        'force|f' => \my $force,
        'sql:s' => \my $sql,
        'help|h' => \my $help,
        'man' => \my $man,
    )) {
        return {
        user     => $user,
        password => $password,
        dsn      => $dsn,
        verbose  => $verbose,
        force    => $force,
        sql      => $sql,
        help     => $help,
        man      => $man,
        };
    } else {
        return undef;
    };
}

sub handle_command_line {
    my ($package,$appname,@argv) =  @_;
    
    my $opts = $package->parse_command_line(@argv)
        or pod2usage(2);
    pod2usage(1) if $opts->{help};
    pod2usage(-verbose => 2) if $opts->{man};
    
    $opts->{dsn} ||= sprintf 'dbi:SQLite:dbname=db/%s.sqlite', $appname;
    
    $package->create(
        %$opts
    );
}

1;

=head1 PROGRAMMER USAGE

This module abstracts away the "run these SQL statements to set up 
your database" into a module. In some situations you want to give the
setup SQL to a database admin, but in other situations, for example testing,
you want to run the SQL statements against an in-memory database. This
module abstracts away the reading of SQL from a file and allows for various
command line parameters to be passed in. A skeleton C<create-db.sql>
looks like this:

    #!/usr/bin/perl -w
    use strict;
    use lib 'lib';
    use DBIx::RunSQL;

    DBIx::RunSQL->handle_command_line('myapp');

    =head1 NAME

    create-db.pl - Create the database

    =head1 ABSTRACT

    This sets up the database. The following
    options are recognized:

    =over 4

    =item C<--user> USERNAME

    =item C<--password> PASSWORD

    =item C<--dsn> DSN

    The DBI DSN to use for connecting to
    the database

    =item C<--sql> SQLFILE

    The alternative SQL file to use
    instead of C<sql/create.sql>.

    =item C<--force>

    Don't stop on errors

    =item C<--help>

    Show this message.

    =cut

=head2 C<< DBIx::RunSQL->handle_command_line >>

Parses the command line. This is a convenience method, which
passes the following command line arguments to C<< ->create >>:

  --user
  --password
  --dsn
  --sql
  --force
  --verbose

In addition, it handles the following switches through L<Pod::Usage>:

  --help
  --man

See also the section PROGRAMMER USAGE for a sample program to set
up a database from an SQL file.

=head1 NOTES

If you find yourself wanting to write SELECT statements,
consider looking at L<Querylet> instead, which is geared towards that
and even has an interface for Excel or HTML output.

If you find yourself wanting to write parametrized queries as
C<.sql> files, consider looking at L<Data::Phrasebook::SQL>
or potentially L<DBIx::SQLHandler>.

=head1 SEE ALSO

L<ORLite::Migrate>

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/DBIx--RunSQL>.

=head1 SUPPORT

The public support forum of this module is
L<http://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-RunSQL>
or via mail to L<dbix-runsql-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2009-2011 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
