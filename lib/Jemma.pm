package Jemma;
use Mojo::Base 'Mojolicious';
use Jemma::Schema;

has schema => sub {
  return Jemma::Schema->connect('dbi:SQLite:data.sqlite');
};

# This method will run once at server start
sub startup {
  my $self = shift;

  # Router
  my $r = $self->routes;

  $r->get('/source')->to(action => 'source');
}

sub source {
  my $self = shift;
  exit 1;

  print STDERR "Myself is $self\n";
  my ($data) = Jemma::Schema::Result::Source->all;
  $data //= 'Broken';

  $self->stash(x => $self);
  $self->stash(self => $data);
}

1;
