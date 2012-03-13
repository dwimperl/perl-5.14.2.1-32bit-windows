package Catalyst::Action::Deserialize::View;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';

our $VERSION = '0.99';
$VERSION = eval $VERSION;

sub execute {
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
