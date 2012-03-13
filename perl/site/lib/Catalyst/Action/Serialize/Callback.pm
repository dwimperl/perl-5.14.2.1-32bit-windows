package Catalyst::Action::Serialize::Callback;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';

our $VERSION = '0.99';
$VERSION = eval $VERSION;

sub execute {
    my $self = shift;
    my ( $controller, $c, $callbacks ) = @_;

    my $stash_key = (
            $controller->{'serialize'} ?
                $controller->{'serialize'}->{'stash_key'} :
                $controller->{'stash_key'}
        ) || 'rest';
    my $output = $callbacks->{serialize}->( $c->stash->{$stash_key}, $controller, $c );
    $c->response->output( $output );
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
