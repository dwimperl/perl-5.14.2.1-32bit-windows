# NOTE: Derived from blib\lib\Memoize\ExpireLRU.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Memoize::ExpireLRU;

#line 294 "blib\lib\Memoize\ExpireLRU.pm (autosplit into blib\lib\auto\Memoize\ExpireLRU\ShowStats.al)"
sub ShowStats () {
    ## Utility routine to show statistics
    my($k) = 0;
    my($p) = '';
    foreach my $self (@AllTies) {
	next unless defined($self->{T});
	$p .= "ExpireLRU Statistics:\n" unless $k;
	$k++;

	$p .= <<EOS;

                   ExpireLRU instantiation: $self->{INSTANCE}
                                Cache Size: $self->{CACHESIZE}
                   Experimental Cache Size: $self->{TUNECACHESIZE}
                                Cache Hits: $self->{ch}
                              Cache Misses: $self->{cm}
Additional Cache Hits at Experimental Size: $self->{th}
                             Distribution : Hits
EOS
	for (my $i = 0; $i < $self->{TUNECACHESIZE}; $i++) {
	    if ($i == $self->{CACHESIZE}) {
		$p .= "                                     ----   -----\n";
	    }
	    $p .= sprintf("                                      %3d : %s\n",
			  $i, $self->{T}->[$i]);
	}
    }
    return $p;
}

1;
# end of Memoize::ExpireLRU::ShowStats
