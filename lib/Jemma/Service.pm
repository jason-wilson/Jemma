package Jemma::Service;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;

  my $schema = Jemma->schema;

  $self->stash(service => [
    $schema->resultset('Service')->search(
    { },
    {
      prefetch => 'source',
      order_by => 'me.name',
    }
  )]);
}

1;
