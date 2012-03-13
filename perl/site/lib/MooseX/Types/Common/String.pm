package MooseX::Types::Common::String;

use strict;
use warnings;

our $VERSION = '0.001007';

use MooseX::Types -declare => [
  qw(SimpleStr
     NonEmptySimpleStr
     NumericCode
     LowerCaseSimpleStr
     UpperCaseSimpleStr
     Password
     StrongPassword
     NonEmptyStr
     LowerCaseStr
     UpperCaseStr)
];

use MooseX::Types::Moose qw/Str/;

subtype SimpleStr,
  as Str,
  where { (length($_) <= 255) && ($_ !~ m/\n/) },
  message { "Must be a single line of no more than 255 chars" },
    ( $Moose::VERSION >= 2.0200
        ? inline_as {
            $_[0]->parent()->_inline_check( $_[1] ) . ' && '
                . qq{ ( (length($_[1]) <= 255) && ($_[1] !~ m/\n/) ) };
        }
        : ()
    );

subtype NonEmptySimpleStr,
  as SimpleStr,
  where { length($_) > 0 },
  message { "Must be a non-empty single line of no more than 255 chars" },
    ( $Moose::VERSION >= 2.0200
        ? inline_as {
            $_[0]->parent()->_inline_check( $_[1] ) . ' && '
                . qq{ (length($_[1]) > 0) };
        }
        : ()
    );

subtype NumericCode,
  as NonEmptySimpleStr,
  where { $_ =~ m/^[0-9]+$/ },
  message {
    'Must be a non-empty single line of no more than 255 chars that consists '
	. 'of numeric characters only'
  };

coerce NumericCode,
  from NonEmptySimpleStr,
  via { my $code = $_; $code =~ s/[[:punct:]]//g; return $code };

subtype Password,
  as NonEmptySimpleStr,
  where { length($_) > 3 },
  message { "Must be between 4 and 255 chars" },
    ( $Moose::VERSION >= 2.0200
        ? inline_as {
            $_[0]->parent()->_inline_check( $_[1] ) . ' && '
                . qq{ (length($_[1]) > 3) };
        }
        : ()
    );

subtype StrongPassword,
  as Password,
  where { (length($_) > 7) && (m/[^a-zA-Z]/) },
  message {"Must be between 8 and 255 chars, and contain a non-alpha char" },
    ( $Moose::VERSION >= 2.0200
        ? inline_as {
            $_[0]->parent()->_inline_check( $_[1] ) . ' && '
                . qq{ ( (length($_[1]) > 7) && ($_[1] =~ m/[^a-zA-Z]/) ) };
        }
        : ()
    );

subtype NonEmptyStr,
  as Str,
  where { length($_) > 0 },
  message { "Must not be empty" },
    ( $Moose::VERSION >= 2.0200
        ? inline_as {
            $_[0]->parent()->_inline_check( $_[1] ) . ' && '
                . qq{ (length($_[1]) > 0) };
        }
        : ()
    );

subtype LowerCaseStr,
  as NonEmptyStr,
  where { /^[a-z]+$/xms },
  message { "Must only contain lower case letters" },
    ( $Moose::VERSION >= 2.0200
        ? inline_as {
            $_[0]->parent()->_inline_check( $_[1] ) . ' && '
                . qq{ ( $_[1] =~ m/^[a-z]+\$/xms ) };
        }
        : ()
    );

coerce LowerCaseStr,
  from NonEmptyStr,
  via { lc };

subtype UpperCaseStr,
  as NonEmptyStr,
  where { /^[A-Z]+$/xms },
  message { "Must only contain upper case letters" },
    ( $Moose::VERSION >= 2.0200
        ? inline_as {
            $_[0]->parent()->_inline_check( $_[1] ) . ' && '
                . qq{ ( $_[1] =~ m/^[A-Z]+\$/xms ) };
        }
        : ()
    );

coerce UpperCaseStr,
  from NonEmptyStr,
  via { uc };

subtype LowerCaseSimpleStr,
  as NonEmptySimpleStr,
  where { /^[a-z]+$/x },
  message { "Must only contain lower case letters" },
    ( $Moose::VERSION >= 2.0200
        ? inline_as {
            $_[0]->parent()->_inline_check( $_[1] ) . ' && '
                . qq{ ( $_[1] =~ m/^[a-z]+\$/x ) };
        }
        : ()
    );
  
coerce LowerCaseSimpleStr,
  from NonEmptySimpleStr,
  via { lc };

subtype UpperCaseSimpleStr,
  as NonEmptySimpleStr,
  where { /^[A-Z]+$/x },
  message { "Must only contain upper case letters" },
    ( $Moose::VERSION >= 2.0200
        ? inline_as {
            $_[0]->parent()->_inline_check( $_[1] ) . ' && '
                . qq{ ( $_[1] =~ m/^[A-Z]+\$/x ) };
        }
        : ()
    );

coerce UpperCaseSimpleStr,
  from NonEmptySimpleStr,
  via { uc };

1;

=head1 NAME

MooseX::Types::Common::String - Commonly used string types

=head1 SYNOPSIS

    use MooseX::Types::Common::String qw/SimpleStr/;
    has short_str => (is => 'rw', isa => SimpleStr);

    ...
    #this will fail
    $object->short_str("string\nwith\nbreaks");

=head1 DESCRIPTION

A set of commonly-used string type constraints that do not ship with Moose by
default.

=over

=item * SimpleStr

A Str with no new-line characters.

=item * NonEmptySimpleStr

A Str with no new-line characters and length > 0

=item * LowerCaseSimpleStr

A Str with no new-line characters, length > 0 and all lowercase characters
A coercion exists via C<lc> from NonEmptySimpleStr

=item * UpperCaseSimpleStr

A Str with no new-line characters, length > 0 and all uppercase characters
A coercion exists via C<uc> from NonEmptySimpleStr

=item * Password

=item * StrongPassword

=item * NonEmptyStr

A Str with length > 0

=item * LowerCaseStr

A Str with length > 0 and all lowercase characters.
A coercion exists via C<lc> from NonEmptyStr

=item * UpperCaseStr

A Str with length > 0 and all uppercase characters.
A coercion exists via C<uc> from NonEmptyStr

=item * NumericCode

A Str with no new-line characters that consists of only Numeric characters.
Examples include, Social Security Numbers, PINs, Postal Codes, HTTP Status
Codes, etc. Supports attempting to coerce from a string that has punctuation
in it ( e.g credit card number 4111-1111-1111-1111 ).

=back

=head1 SEE ALSO

=over

=item * L<MooseX::Types::Common::Numeric>

=back

=head1 AUTHORS

Please see:: L<MooseX::Types::Common>

=cut
