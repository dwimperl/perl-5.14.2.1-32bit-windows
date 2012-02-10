package Module::ScanDeps::DataFeed;

use strict; 
use vars qw( %_INC @_INC @_dl_shared_objects @_dl_modules $_0 );

require Cwd;
require DynaLoader;
require Data::Dumper;
require B; 
require Config;

# Write %_INC, @_INC etc to $filename
sub _dump_info 
{
    my ($filename) = @_;

    while (my ($k, $v) = each %_INC)
    {
        # Notes:
        # (1) An unsuccessful "require" may store an undefined value into %INC.
        # (2) If a key in %INC was located via a CODE or ARRAY ref or
        #     blessed object in @INC the corresponding value in %INC contains
        #     the ref from @INC.
        if (defined $v && !ref $v)
        {
            $_INC{$k} = Cwd::abs_path($v);
        }
        else
        {
            delete $_INC{$k};
        }
    }

    # drop refs from @_INC
    @_INC = grep { !ref $_ } @_INC;

    my $dlext = $Config::Config{dlext};
    my @so = grep { defined $_ && -e $_ } _dl_shared_objects();
    my @bs = @so;
    my @shared_objects = ( @so, grep { s/\Q.$dlext\E$/\.bs/ && -e $_ } @bs );

    open my $fh, ">", $filename 
        or die "Couldn't open $filename: $!\n";
    print $fh Data::Dumper->Dump(
                  [\%_INC, \@_INC, \@shared_objects], 
                  [qw(*inchash *incarray *dl_shared_objects)]);
    print $fh "1;\n";
    close $fh;
}

sub _dl_shared_objects {
    if (@_dl_shared_objects) {
        return @_dl_shared_objects;
    }
    elsif (@_dl_modules) {
        return map { _dl_mod2filename($_) } @_dl_modules;
    }
    return;
}

sub _dl_mod2filename {
    my $mod = shift;

    return if $mod eq 'B';
    return unless defined &{"$mod\::bootstrap"};

    my $dl_ext = $Config::Config{dlext};

    # Copied from XSLoader
    my @modparts = split(/::/, $mod);
    my $modfname = $modparts[-1];
    my $modpname = join('/', @modparts);

    foreach my $dir (@_INC) {
        my $file = "$dir/auto/$modpname/$modfname.$dl_ext";
        return $file if -r $file;
    }

    return;
}

1;

__END__

# AUTHORS
# 
# Edward S. Peschko <esp5@pge.comE>,
# Audrey Tang <cpan@audreyt.org>,
# to a lesser degree Steffen Mueller <smueller@cpan.org>
# 
# COPYRIGHT
# 
# Copyright 2004-2009 by Edward S. Peschko <esp5@pge.com>,
# Audrey Tang <cpan@audreyt.org>,
# Steffen Mueller <smueller@cpan.org>
# 
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# 
# See <http://www.perl.com/perl/misc/Artistic.html

