package Moose::Autobox::Array;
use Moose::Role 'with';
use Perl6::Junction;
use Moose::Autobox;

our $VERSION = '0.11';

with 'Moose::Autobox::Ref',
     'Moose::Autobox::List',
     'Moose::Autobox::Indexed';
    
## Array Interface

sub pop { 
    my ($array) = @_;    
    CORE::pop @$array; 
}

sub push { 
    my ($array, @rest) = @_;
    CORE::push @$array, @rest;  
    $array; 
}

sub unshift { 
    my ($array, @rest) = @_;    
    CORE::unshift @$array, @rest; 
    $array; 
}

sub delete { 
    my ($array, $index) = @_;    
    CORE::delete $array->[$index];
}

sub shift { 
    my ($array) = @_;    
    CORE::shift @$array; 
}    

sub slice {
    my ($array, $indicies) = @_;
    [ @{$array}[ @{$indicies} ] ];
} 

# NOTE: 
# sprintf args need to be reversed, 
# because the invocant is the array
sub sprintf { CORE::sprintf $_[1], @{$_[0]} }

## ::List interface implementation

sub head { $_[0]->[0] }
sub tail { [ @{$_[0]}[ 1 .. $#{$_[0]} ] ] }
 
sub length {
    my ($array) = @_;
    CORE::scalar @$array;
}

sub grep { 
    my ($array, $sub) = @_; 
    [ CORE::grep { $sub->($_) } @$array ]; 
}

sub map { 
    my ($array, $sub) = @_; 
    [ CORE::map { $sub->($_) } @$array ]; 
}

sub join { 
    my ($array, $sep) = @_;    
    $sep ||= ''; 
    CORE::join $sep, @$array; 
}

sub reverse { 
    my ($array) = @_;
    [ CORE::reverse @$array ];
}

sub sort { 
    my ($array, $sub) = @_;     
    $sub ||= sub { $a cmp $b }; 
    [ CORE::sort { $sub->($a, $b) } @$array ]; 
}    

sub first {
    $_[0]->[0];
}

sub last {
    $_[0]->[$#{$_[0]}];
}

## ::Indexed implementation

sub at {
    my ($array, $index) = @_;
    $array->[$index];
} 

sub put {
    my ($array, $index, $value) = @_;
    $array->[$index] = $value;
}

sub exists {
    my ($array, $index) = @_;    
    CORE::exists $array->[$index];    
}

sub keys { 
    my ($array) = @_;    
    [ 0 .. $#{$array} ];
}

sub values { 
    my ($array) = @_;    
    [ @$array ];
}

sub kv {
    my ($array) = @_;   
    $array->keys->map(sub { [ $_, $array->[$_] ] });
}

sub each {
    my ($array, $sub) = @_;
    for my $i (0 .. $#$array) {
      $sub->($i, $array->[ $i ]);
    }
}

sub each_key {
    my ($array, $sub) = @_;
    $sub->($_) for (0 .. $#$array);
}

sub each_value {
    my ($array, $sub) = @_;
    $sub->($_) for @$array;
}

sub each_n_values {
    my ($array, $n, $sub) = @_;
    my $it = List::MoreUtils::natatime($n, @$array);

    while (my @vals = $it->()) {
        $sub->(@vals);
    }

    return;
}

# end indexed

sub flatten {
    @{$_[0]}
}

sub _flatten_deep { 
	my @array = @_;
	my $depth = CORE::pop @array;
	--$depth if (defined($depth));
	
	CORE::map {
		(ref eq 'ARRAY')
			? (defined($depth) && $depth == -1) ? $_ : _flatten_deep( @$_, $depth )
			: $_
	} @array;

}

sub flatten_deep { 
	my ($array, $depth) = @_;	
	[ _flatten_deep(@$array, $depth) ];
}

## Junctions

sub all {
    my ($array) = @_;     
    return Perl6::Junction::all(@$array);
}

sub any {
    my ($array) = @_;     
    return Perl6::Junction::any(@$array);
}

sub none {
    my ($array) = @_;     
    return Perl6::Junction::none(@$array);
}

sub one {
    my ($array) = @_; 
    return Perl6::Junction::one(@$array);
}

## Print

sub print { CORE::print @{$_[0]} }
sub say   { CORE::print @{$_[0]}, "\n" }

1;

__END__

=pod

=head1 NAME 

Moose::Autobox::Array - the Array role

=head1 SYNOPOSIS

  use Moose::Autobox;
    
  [ 1..5 ]->isa('ARRAY'); # true
  [ a..z ]->does('Moose::Autobox::Array'); # true
  [ 0..2 ]->does('Moose::Autobox::List'); # true  
    
  print "Squares: " . [ 1 .. 10 ]->map(sub { $_ * $_ })->join(', ');
  
  print [ 1, 'number' ]->sprintf('%d is the loneliest %s');
  
  print ([ 1 .. 5 ]->any == 3) ? 'true' : 'false'; # prints 'true'

=head1 DESCRIPTION

This is a role to describe operations on the Array type. 

=head1 METHODS

=over 4

=item B<pop>

=item B<push ($value)>

=item B<shift>

=item B<unshift ($value)>

=item B<delete ($index)>

=item B<sprintf ($format_string)>

=item B<slice (@indices)>

=item B<flatten>

=item B<flatten_deep ($depth)>

=item B<first>

=item B<last>

=back

=head2 Indexed implementation

=over 4

=item B<at ($index)>

=item B<put ($index, $value)>

=item B<exists ($index)>

=item B<keys>

=item B<values>

=item B<kv>

=item B<each>

=item B<each_key>

=item B<each_value>

=item B<each_n_values ($n, $callback)>

=back

=head2 List implementation

=over 4

=item B<head>

=item B<tail>

=item B<join (?$seperator)>

=item B<length>

=item B<map (\&block)>

=item B<grep (\&block)>

Note that, in both the above, $_ is in scope within the code block, as well as 
being passed as $_[0]. As per CORE::map and CORE::grep, $_ is an alias to 
the list value, so can be used to to modify the list, viz:

    use Moose::Autobox;

    my $foo = [1, 2, 3]; 
    $foo->map( sub {$_++} ); 
    print $foo->dump;

yields

   $VAR1 = [
             2,
             3,
             4
           ];
        
=item B<reverse>

=item B<sort (?\&block)>

=back

=head2 Junctions

=over 4

=item B<all>

=item B<any>

=item B<none>

=item B<one>

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
