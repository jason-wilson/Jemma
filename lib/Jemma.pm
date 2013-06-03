package Jemma;
use Mojo::Base 'Mojolicious';
use Jemma::Utils;

has schema => sub {
  return Jemma::Schema->connect('dbi:SQLite:data.sqlite');
};

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->stash(ipaddr => 'boo');

  my $r = $self->routes;
  $r->get('/source')          ->to(controller => 'source', action => 'show' );
  $r->get('/ip')              ->to(controller => 'ip',     action => 'show' );
  $r->get('/ip/like/*match')  ->to(controller => 'ip',     action => 'match');
  $r->get('/ip/name/*name')   ->to(controller => 'ip',     action => 'name' );
  $r->get('/group')           ->to(controller => 'group',  action => 'show' );
  $r->get('/group/name/*name')->to(controller => 'group',  action => 'name' );

  $r->post('/ip/search')      ->to(controller => 'ip',     action => 'search' );

  $self->helper(n2ip => sub { Jemma::Utils::number_to_ip($_[1]) } );
  $self->helper(r2c  => sub { Jemma::Utils::range_to_cidr($_[1], $_[2]) } );
}

1;
