package Web::Simple::DispatchNode;

use Moo;

extends 'Web::Dispatch::Node';

has _app_object => (is => 'ro', init_arg => 'app_object', required => 1);

# this ensures that the dispatchers get called as methods of the app itself
around _curry => sub {
  my ($orig, $self) = (shift, shift);
  $self->$orig($self->_app_object, @_);
};

1;
