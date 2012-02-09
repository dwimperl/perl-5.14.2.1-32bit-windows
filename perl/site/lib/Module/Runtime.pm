=head1 NAME

Module::Runtime - runtime module handling

=head1 SYNOPSIS

	use Module::Runtime qw(
		$module_name_rx is_module_name check_module_name
		module_notional_filename require_module
	);

	if($module_name =~ /\A$module_name_rx\z/o) { ...
	if(is_module_name($module_name)) { ...
	check_module_name($module_name);

	$notional_filename = module_notional_filename($module_name);
	require_module($module_name);

	use Module::Runtime qw(use_module use_package_optimistically);

	$bi = use_module("Math::BigInt", 1.31)->new("1_234");
	$widget = use_package_optimistically("Local::Widget")->new;

	use Module::Runtime qw(
		$top_module_spec_rx $sub_module_spec_rx
		is_module_spec check_module_spec
		compose_module_name
	);

	if($spec =~ /\A$top_module_spec_rx\z/o) { ...
	if($spec =~ /\A$sub_module_spec_rx\z/o) { ...
	if(is_module_spec("Standard::Prefix", $spec)) { ...
	check_module_spec("Standard::Prefix", $spec);

	$module_name =
		compose_module_name("Standard::Prefix", $spec);

=head1 DESCRIPTION

The functions exported by this module deal with runtime handling of Perl
modules, which are normally handled at compile time.

=cut

package Module::Runtime;

{ use 5.006; }
use warnings;
use strict;

use Params::Classify 0.000 qw(is_string);

our $VERSION = "0.011";

use parent "Exporter";
our @EXPORT_OK = qw(
	$module_name_rx is_module_name is_valid_module_name check_module_name
	module_notional_filename require_module
	use_module use_package_optimistically
	$top_module_spec_rx $sub_module_spec_rx
	is_module_spec is_valid_module_spec check_module_spec
	compose_module_name
);

=head1 REGULAR EXPRESSIONS

These regular expressions do not include any anchors, so to check
whether an entire string matches a syntax item you must supply the
anchors yourself.

=over

=item $module_name_rx

Matches a valid Perl module name in bareword syntax.
The rule for this, precisely, is: the string must
consist of one or more segments separated by C<::>; each segment must
consist of one or more identifier characters (alphanumerics plus "_");
the first character of the string must not be a digit.  Thus "C<IO::File>",
"C<warnings>", and "C<foo::123::x_0>" are all valid module names, whereas
"C<IO::>" and "C<1foo::bar>" are not.
Only ASCII characters are permitted; Perl's handling of non-ASCII
characters in source code is inconsistent.
C<'> separators are not permitted.

=cut

our $module_name_rx = qr/[A-Z_a-z][0-9A-Z_a-z]*(?:::[0-9A-Z_a-z]+)*/;

=item $top_module_spec_rx

Matches a module specification for use with L</compose_module_name>,
where no prefix is being used.

=cut

my $qual_module_spec_rx =
	qr#(?:/|::)[A-Z_a-z][0-9A-Z_a-z]*(?:(?:/|::)[0-9A-Z_a-z]+)*#;

my $unqual_top_module_spec_rx =
	qr#[A-Z_a-z][0-9A-Z_a-z]*(?:(?:/|::)[0-9A-Z_a-z]+)*#;

our $top_module_spec_rx = qr/$qual_module_spec_rx|$unqual_top_module_spec_rx/o;

=item $sub_module_spec_rx

Matches a module specification for use with L</compose_module_name>,
where a prefix is being used.

=cut

my $unqual_sub_module_spec_rx = qr#[0-9A-Z_a-z]+(?:(?:/|::)[0-9A-Z_a-z]+)*#;

our $sub_module_spec_rx = qr/$qual_module_spec_rx|$unqual_sub_module_spec_rx/o;

=back

=head1 FUNCTIONS

=head2 Basic module handling

=over

=item is_module_name(ARG)

Returns a truth value indicating whether I<ARG> is a plain string
satisfying Perl module name syntax as described for L</$module_name_rx>.

=cut

sub is_module_name($) { is_string($_[0]) && $_[0] =~ /\A$module_name_rx\z/o }

=item is_valid_module_name(ARG)

Deprecated alias for L</is_module_name>.

=cut

*is_valid_module_name = \&is_module_name;

=item check_module_name(ARG)

Check whether I<ARG> is a plain string
satisfying Perl module name syntax as described for L</$module_name_rx>.
Return normally if it is, or C<die> if it is not.

=cut

sub check_module_name($) {
	unless(&is_module_name) {
		die +(is_string($_[0]) ? "`$_[0]'" : "argument").
			" is not a module name\n";
	}
}

=item module_notional_filename(NAME)

Generates a notional relative filename for a module, which is used in
some Perl core interfaces.
The I<NAME> is a string, which should be a valid module name (one or
more C<::>-separated segments).  If it is not a valid name, the function
C<die>s.

The notional filename for the named module is generated and returned.
This filename is always in Unix style, with C</> directory separators
and a C<.pm> suffix.  This kind of filename can be used as an argument to
C<require>, and is the key that appears in C<%INC> to identify a module,
regardless of actual local filename syntax.

=cut

sub module_notional_filename($) {
	&check_module_name;
	my($name) = @_;
	$name =~ s!::!/!g;
	return $name.".pm";
}

=item require_module(NAME)

This is essentially the bareword form of C<require>, in runtime form.
The I<NAME> is a string, which should be a valid module name (one or
more C<::>-separated segments).  If it is not a valid name, the function
C<die>s.

The module specified by I<NAME> is loaded, if it hasn't been already,
in the manner of the bareword form of C<require>.  That means that a
search through C<@INC> is performed, and a byte-compiled form of the
module will be used if available.

The return value is as for C<require>.  That is, it is the value returned
by the module itself if the module is loaded anew, or C<1> if the module
was already loaded.

=cut

sub require_module($) {
	# Explicit scalar() here works around a Perl core bug, present
	# in Perl 5.8 and 5.10, which allowed a require() in return
	# position to pass a non-scalar context through to file scope
	# of the required file.  This breaks some modules.  require()
	# in any other position, where its op flags determine context
	# statically, doesn't have this problem, because the op flags
	# are forced to scalar.
	return scalar(require(&module_notional_filename));
}

=back

=head2 Structured module use

=over

=item use_module(NAME[, VERSION])

This is essentially C<use> in runtime form, but without the importing
feature (which is fundamentally a compile-time thing).  The I<NAME> is
handled just like in C<require_module> above: it must be a module name,
and the named module is loaded as if by the bareword form of C<require>.

If a I<VERSION> is specified, the C<VERSION> method of the loaded module is
called with the specified I<VERSION> as an argument.  This normally serves to
ensure that the version loaded is at least the version required.  This is
the same functionality provided by the I<VERSION> parameter of C<use>.

On success, the name of the module is returned.  This is unlike
L</require_module>, and is done so that the entire call to L</use_module>
can be used as a class name to call a constructor, as in the example in
the synopsis.

=cut

sub use_module($;$) {
	my($name, $version) = @_;
	require_module($name);
	if(defined $version) {
		$name->VERSION($version);
	}
	return $name;
}

=item use_package_optimistically(NAME[, VERSION])

This is an analogue of L</use_module> for the situation where there is
uncertainty as to whether a package/class is defined in its own module
or by some other means.  It attempts to arrange for the named package to
be available, either by loading a module or by doing nothing and hoping.

An attempt is made to load the named module (as if by the bareword form
of C<require>).  If the module cannot be found then it is assumed that
the package was actually already loaded but wasn't detected correctly,
and no error is signalled.  That's the optimistic bit.

This is mostly the same operation that is performed by the L<base> pragma
to ensure that the specified base classes are available.  The behaviour
of L<base> was simplified in version 2.18, and this function changed
to match.

If a I<VERSION> is specified, the C<VERSION> method of the loaded package is
called with the specified I<VERSION> as an argument.  This normally serves
to ensure that the version loaded is at least the version required.
On success, the name of the package is returned.  These aspects of the
function work just like L</use_module>.

=cut

sub use_package_optimistically($;$) {
	my($name, $version) = @_;
	check_module_name($name);
	eval { local $SIG{__DIE__}; require(module_notional_filename($name)); };
	die $@ if $@ ne "" && $@ !~ /\A
		Can't\ locate\ .+\ at
		\ \Q@{[__FILE__]}\E\ line\ \Q@{[__LINE__-1]}\E
	/xs;
	$name->VERSION($version) if defined $version;
	return $name;
}

=back

=head2 Module name composition

=over

=item is_module_spec(PREFIX, SPEC)

Returns a truth value indicating
whether I<SPEC> is valid input for L</compose_module_name>.
See below for what that entails.  Whether a I<PREFIX> is supplied affects
the validity of I<SPEC>, but the exact value of the prefix is unimportant,
so this function treats I<PREFIX> as a truth value.

=cut

sub is_module_spec($$) {
	my($prefix, $spec) = @_;
	return is_string($spec) &&
		$spec =~ ($prefix ? qr/\A$sub_module_spec_rx\z/o :
				    qr/\A$top_module_spec_rx\z/o);
}

=item is_valid_module_spec(PREFIX, SPEC)

Deprecated alias for L</is_module_spec>.

=cut

*is_valid_module_spec = \&is_module_spec;

=item check_module_spec(PREFIX, SPEC)

Check whether I<SPEC> is valid input for L</compose_module_name>.
Return normally if it is, or C<die> if it is not.

=cut

sub check_module_spec($$) {
	unless(&is_module_spec) {
		die +(is_string($_[1]) ? "`$_[1]'" : "argument").
			" is not a module specification\n";
	}
}

=item compose_module_name(PREFIX, SPEC)

This function is intended to make it more convenient for a user to specify
a Perl module name at runtime.  Users have greater need for abbreviations
and context-sensitivity than programmers, and Perl module names get a
little unwieldy.  I<SPEC> is what the user specifies, and this function
translates it into a module name in standard form, which it returns.

I<SPEC> has syntax approximately that of a standard module name: it
should consist of one or more name segments, each of which consists
of one or more identifier characters.  However, C</> is permitted as a
separator, in addition to the standard C<::>.  The two separators are
entirely interchangeable.

Additionally, if I<PREFIX> is not C<undef> then it must be a module
name in standard form, and it is prefixed to the user-specified name.
The user can inhibit the prefix addition by starting I<SPEC> with a
separator (either C</> or C<::>).

=cut

sub compose_module_name($$) {
	my($prefix, $spec) = @_;
	check_module_name($prefix) if defined $prefix;
	&check_module_spec;
	if($spec =~ s#\A(?:/|::)##) {
		# OK
	} else {
		$spec = $prefix."::".$spec if defined $prefix;
	}
	$spec =~ s#/#::#g;
	return $spec;
}

=back

=head1 SEE ALSO

L<base>,
L<perlfunc/require>,
L<perlfunc/use>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2004, 2006, 2007, 2009, 2010, 2011
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
