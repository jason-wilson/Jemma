package Jemma;
use Mojo::Base 'Mojolicious';

has schema => sub {
  return Jemma::Schema->connect('dbi:SQLite:data.sqlite');
};

# This method will run once at server start
sub startup {
  my $self = shift;

  print STDERR "Myself is $self\n";
  # Router
  my $r = $self->routes;
  print STDERR "r is a $r\n";
  for my $ns ($r->namespaces) {
    print STDERR "Namespace is ", $ns, "\n";
    for (@{$ns}) {
      print STDERR "  Which has: ", $_, "\n";
    }
  }

  $r->get('/source')->to(controller => 'source', action => 'show');
}

1;
