package Web::Dispatch::Node;

use Moo;

with 'Web::Dispatch::ToApp';

for (qw(match run)) {
  has "_${_}" => (is => 'ro', required => 1, init_arg => $_);
}

sub call {
  my ($self, $env) = @_;
  if (my ($env_delta, @match) = $self->_match->($env)) {
    ($env_delta, $self->_curry(@match));
  } else {
    ()
  }
}

sub _curry {
  my ($self, @args) = @_;
  my $run = $self->_run;
  sub { $run->(@args, $_[0]) };
}

1;
