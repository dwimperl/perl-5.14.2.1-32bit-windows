# NOTE: Derived from blib\lib\Memoize\ExpireLRU.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Memoize::ExpireLRU;

#line 271 "blib\lib\Memoize\ExpireLRU.pm (autosplit into blib\lib\auto\Memoize\ExpireLRU\DumpCache.al)"
sub DumpCache ( $ ) {
    ## Utility routine to display the caches of the given instance
    my($Instance, $self, $p) = shift;
    foreach $self (@AllTies) {

	next unless $self->{INSTANCE} eq $Instance;

	$p = "$Instance:\n    Cache Keys:\n";

	foreach my $x (@{$self->{I}}) {
	    ## The cache is at $self->{C} (->{$key})
	    $p .= "        '$x->{k}'\n";
	}
	$p .= "    Test Cache Keys:\n";
	foreach my $x (@{$self->{TI}}) {
	    $p .= "        '$x->{k}'\n";
	}
	return $p;
    }
    return "Instance $Instance not found\n";
}

# end of Memoize::ExpireLRU::DumpCache
1;
