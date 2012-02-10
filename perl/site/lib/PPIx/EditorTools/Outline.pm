package PPIx::EditorTools::Outline;

# ABSTRACT: Collect use pragmata, modules, subroutiones, methods, attributes

use 5.008;
use strict;
use warnings;
use Carp;

use base 'PPIx::EditorTools';
use Class::XSAccessor accessors => {};

use PPI;

our $VERSION = '0.15';

=pod

=head1 SYNOPSIS

  my $outline = PPIx::EditorTools::Outline->new->find(
        code => "package TestPackage;\nsub x { 1;\n"
      );
 print Dumper $outline;

=head1 DESCRIPTION

Return a list of pragmatas, modules, methods, attributes of a C<PPI::Document>.

=head1 METHODS

=over 4

=item new()

Constructor. Generally shouldn't be called with any arguments.

=item find( ppi => PPI::Document $ppi )
=item find( code => Str $code )

Accepts either a C<PPI::Document> to process or a string containing
the code (which will be converted into a C<PPI::Document>) to process.
Return a reference to a hash.

=back

=cut

sub find {
	my ( $self, %args ) = @_;
	$self->process_doc(%args);

	my $ppi = $self->ppi;

	return [] unless defined $ppi;
	$ppi->index_locations;

	# Search for interesting things
	require PPI::Find;

	# TODO things not very discriptive
	my @things = PPI::Find->new(
		sub {

			# This is a fairly ugly search
			return 1 if ref $_[0] eq 'PPI::Statement::Package';
			return 1 if ref $_[0] eq 'PPI::Statement::Include';
			return 1 if ref $_[0] eq 'PPI::Statement::Sub';
			return 1 if ref $_[0] eq 'PPI::Statement';
		}
	)->in($ppi);

	# Define a flag indicating that further Method::Signature/Moose check should run
	my $check_alternate_sub_decls = 0;

	# Build the outline structure from the search results
	my @outline       = ();
	my $cur_pkg       = {};
	my $not_first_one = 0;
	foreach my $thing (@things) {
		if ( ref $thing eq 'PPI::Statement::Package' ) {
			if ($not_first_one) {
				if ( not $cur_pkg->{name} ) {
					$cur_pkg->{name} = 'main';
				}
				push @outline, $cur_pkg;
				$cur_pkg = {};
			}
			$not_first_one   = 1;
			$cur_pkg->{name} = $thing->namespace;
			$cur_pkg->{line} = $thing->location->[0];
		} elsif ( ref $thing eq 'PPI::Statement::Include' ) {
			next if $thing->type eq 'no';
			if ( $thing->pragma ) {
				push @{ $cur_pkg->{pragmata} }, { name => $thing->pragma, line => $thing->location->[0] };
			} elsif ( $thing->module ) {
				push @{ $cur_pkg->{modules} }, { name => $thing->module, line => $thing->location->[0] };
				unless ($check_alternate_sub_decls) {
					$check_alternate_sub_decls = 1
						if grep { $thing->module eq $_ } (
						'Method::Signatures',
						'MooseX::Declare',
						'MooseX::Method::Signatures'
						);
				}
			}
		} elsif ( ref $thing eq 'PPI::Statement::Sub' ) {
			push @{ $cur_pkg->{methods} }, { name => $thing->name, line => $thing->location->[0] };
		} elsif ( ref $thing eq 'PPI::Statement' ) {

			# last resort, let's analyse further down...
			my $node1 = $thing->first_element;
			my $node2 = $thing->child(2);
			next unless defined $node2;

			# Moose attribute declaration
			if ( $node1->isa('PPI::Token::Word') && $node1->content eq 'has' ) {
				$self->_Moo_Attributes( $node2, $cur_pkg, $thing );
				next;
			}

			# MooseX::POE event declaration
			if ( $node1->isa('PPI::Token::Word') && $node1->content eq 'event' ) {
				push @{ $cur_pkg->{events} }, { name => $node2->content, line => $thing->location->[0] };
				next;
			}
		}
	}

	if ($check_alternate_sub_decls) {
		$ppi->find(
			sub {
				$_[1]->isa('PPI::Token::Word') or return 0;
				$_[1]->content =~ /^(?:func|method|before|after|around|override|augment|class|role)\z/ or return 0;
				$_[1]->next_sibling->isa('PPI::Token::Whitespace') or return 0;
				my $sib_content = $_[1]->next_sibling->next_sibling->content or return 0;

				$sib_content =~ m/^\b(\w+)\b/;
				return 0 unless defined $1;

				# test for MooseX::Declare class, role
				if ( $_[1]->content =~ m/(class|role)/ ) {
					$self->_Moo_PkgName( $cur_pkg, $sib_content, $_[1] );
					return 1; # break out so we don't write Packae name as method
				}

				push @{ $cur_pkg->{methods} }, { name => $1, line => $_[1]->line_number };

				return 1;
			}
		);
	}

	if ( not $cur_pkg->{name} ) {
		$cur_pkg->{name} = 'main';
	}

	push @outline, $cur_pkg;

	return \@outline;
}

########
# Composed Method, internal, Moose Attributes
# cleans moose attributes up, and single lines them.
# only runs if PPI finds has
# prefix all vars with ma_ otherwise same name
########
sub _Moo_Attributes {
	my ( $self, $ma_node2, $ma_cur_pkg, $ma_thing ) = @_;

	# tidy up Moose attributes for Outline display
	my $ma_has_att = $ma_node2->content;
	my $space      = q{ };
	$ma_has_att =~ s/^\[?(qw(\/|\())?$space?//;   # remove leading 'quote word'
	$ma_has_att =~ s/(\/|\))?\]?$//;              # remove traling 'quote word'
	$ma_has_att =~ s/(\'$space?)//g;              # remove Single-Quoted String Literals
	$ma_has_att =~ s/($space?\,$space?)/$space/g; # remove commers add space
	                                              # split mulitline attributes to one per line
	my @ma_atts_found = split /$space/, $ma_has_att,;

	foreach my $ma_att (@ma_atts_found) {

		# add to outline
		push @{ $ma_cur_pkg->{attributes} }, { name => $ma_att, line => $ma_thing->location->[0] };
	}
	return;
}

########
# Composed Method, internal, Moose Pakage Name
# write first Class or Role as Package Name if none
# prefix all vars with mpn_ otherwise same name
########
sub _Moo_PkgName {
	my ( $self, $mpn_cur_pkg, $mpn_sib_content, $mpn_ppi_tuple ) = @_;
	if ( $mpn_cur_pkg->{name} ) { return 1; } # break if we have a pkg name
	                                          # add to outline
	$mpn_cur_pkg->{name} = $mpn_sib_content;            # class or role name
	$mpn_cur_pkg->{line} = $mpn_ppi_tuple->line_number; # class or role location
	return 1;
}

1;

__END__

=head1 SEE ALSO

This class inherits from C<PPIx::EditorTools>.
Also see L<App::EditorTools>, L<Padre>, and L<PPI>.

=cut

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

