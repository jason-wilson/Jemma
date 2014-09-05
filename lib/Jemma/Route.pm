package Jemma::Route;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;

  my $schema = new Jemma->schema;

  $self->stash(route => [
    $schema->resultset('Route')->all ]);

}

1;
