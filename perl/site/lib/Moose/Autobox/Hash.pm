package Moose::Autobox::Hash;
use Moose::Role 'with';

our $VERSION = '0.11';

with 'Moose::Autobox::Ref',
     'Moose::Autobox::Indexed';

sub delete { 
    my ($hash, $key) = @_;
    CORE::delete $hash->{$key}; 
}

sub merge {
    my ($left, $right) = @_;
    Carp::confess "You must pass a hashref as argument to merge"
        unless ref $right eq 'HASH';
    return { %$left, %$right };
}

sub hslice {
    my ($hash, $keys) = @_;
    return { map { $_ => $hash->{$_} } @$keys };
}

sub flatten {
    return %{$_[0]}
}

# ::Indexed implementation

sub at {
    my ($hash, $index) = @_;
    $hash->{$index};
} 

sub put {
    my ($hash, $index, $value) = @_;
    $hash->{$index} = $value;
}

sub exists { 
    my ($hash, $key) = @_;
    CORE::exists $hash->{$key}; 
}

sub keys { 
    my ($hash) = @_;
    [ CORE::keys %$hash ];
}

sub values { 
    my ($hash) = @_;    
    [ CORE::values %$hash ]; 
}

sub kv {
    my ($hash) = @_;    
    [ CORE::map { [ $_, $hash->{$_} ] } CORE::keys %$hash ];    
}

sub slice {
    my ($hash, $keys) = @_;
    return [ @{$hash}{@$keys} ];
}

sub each {
    my ($hash, $sub) = @_;
    for my $key (CORE::keys %$hash) {
      $sub->($key, $hash->{$key});
    }
}

sub each_key {
    my ($hash, $sub) = @_;
    $sub->($_) for CORE::keys %$hash;
}

sub each_value {
    my ($hash, $sub) = @_;
    $sub->($_) for CORE::values %$hash;
}

sub each_n_values {
    my ($hash, $n, $sub) = @_;
    my @keys = CORE::keys %$hash;
    my $it = List::MoreUtils::natatime($n, @keys);

    while (my @vals = $it->()) {
        $sub->(@$hash{ @vals });
    }

    return;
}


# End Indexed

sub print   { CORE::print %{$_[0]} }
sub say     { CORE::print %{$_[0]}, "\n" }

1;

__END__

=pod

=head1 NAME 

Moose::Autobox::Hash - the Hash role

=head1 SYNOPOSIS

  use Moose::Autobox;
  
  print { one => 1, two => 2 }->keys->join(', '); # prints 'one, two'

=head1 DESCRIPTION

This is a role to describes a Hash value. 

=head1 METHODS

=over 4

=item B<delete>

=item B<merge>

Takes a hashref and returns a new hashref with right precedence
shallow merging.

=item B<hslice>

Slices a hash but returns the keys and values as a new hashref.

=item B<flatten>

=back

=head2 Indexed implementation

=over 4

=item B<at>

=item B<put>

=item B<exists>

=item B<keys>

=item B<values>

=item B<kv>

=item B<slice>

=item B<each>

=item B<each_key>

=item B<each_value>

=item B<each_n_values>

=back

=over 4

=item B<meta>

=item B<print>

=item B<say>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

