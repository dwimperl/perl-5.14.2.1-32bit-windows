package Catalyst::Action::Serialize::Data::Serializer;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
use Data::Serializer;

our $VERSION = '0.99';
$VERSION = eval $VERSION;

sub execute {
    my $self = shift;
    my ( $controller, $c, $serializer ) = @_;

    my $stash_key = (
            $controller->{'serialize'} ?
                $controller->{'serialize'}->{'stash_key'} :
                $controller->{'stash_key'} 
        ) || 'rest';
    my $sp = $serializer;
    $sp =~ s/::/\//g;
    $sp .= ".pm";
    eval {
        require $sp
    };
    if ($@) {
        $c->log->info("Could not load $serializer, refusing to serialize: $@");
        return;
    }
    my $dso = Data::Serializer->new( serializer => $serializer );
    my $data = $dso->raw_serialize($c->stash->{$stash_key});
    $c->response->output( $data );
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
