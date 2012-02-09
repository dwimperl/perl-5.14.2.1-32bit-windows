# 
# This file is part of CPAN-Testers-Report
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

package CPAN::Testers::Report;
BEGIN {
  $CPAN::Testers::Report::VERSION = '1.999001';
}
# ABSTRACT: CPAN Testers report object

use Metabase::Report 0.016 ();
our @ISA = qw/Metabase::Report/;
CPAN::Testers::Report->load_fact_classes;

sub report_spec { 
  return {
    'CPAN::Testers::Fact::LegacyReport' => 1,
    'CPAN::Testers::Fact::TestSummary' => 1, # include date
    'CPAN::Testers::Fact::TestOutput' => '0+', # eventually by phase
    'CPAN::Testers::Fact::TesterComment' => '0+',
    'CPAN::Testers::Fact::PerlConfig' => '0+',
    'CPAN::Testers::Fact::TestEnvironment' => '0+',
    'CPAN::Testers::Fact::Prereqs' => '0+', # declared versions
    'CPAN::Testers::Fact::InstalledModules' => '0+', 
    # XXX needs NNTP_ID for old reports -- dagolden, 2009-06-24
    # future goals
    # 'CPAN::Testers::Fact::TAPArchive' => 1, 
  }
}

sub content_metadata {
  my ($self) = @_;
  for my $fact ( $self->facts ) {
    next unless $fact->type eq 'CPAN-Testers-Fact-LegacyReport';
    return $fact->content_metadata;
  }
}
  
sub content_metadata_types {
  my ($self) = @_;
  for my $fact ( $self->facts ) {
    next unless $fact->type eq 'CPAN::Testers::Fact::LegacyReport';
    return $fact->content_metadata_types;
  }
}
  
1;



=pod

=head1 NAME

CPAN::Testers::Report - CPAN Testers report object

=head1 VERSION

version 1.999001

=head1 SYNOPSIS

  my $report = CPAN::Testers::Report->open(
    resource => 'cpan:///distfile/RJBS/CPAN-Metabase-Fact-0.001.tar.gz',
  );

  $report->add( CPAN::Testers::Fact::LegacyReport => {
    grade         => $tr->grade,
    osname        => $tr->osname,
    osversion     => $tr->osversion
    archname      => $tr->archname
    perlversion   => $tr->perl_version_number
    textreport    => $tr->report
  });

  # TestSummary happens to be the same as content metadata 
  # of LegacyReport for now
  $report->add( CPAN::Testers::Fact::TestSummary =>
    $report->facts->[0]->content_metadata()
  );
    
  $report->close();

=head1 DESCRIPTION

Metabase report class encapsulating Facts about a CPAN Testers report

=head1 USAGE

CPAN::Testers::Report subclases L<Metabase::Report>.  See that module for API.
See L<Test::Reporter::Transport::Metabase> for an example of usage.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=CPAN-Testers-Report>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

  David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__




