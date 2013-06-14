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
  $r->get('/')                ->to(controller => 'source', action => 'show' );

  $r->get('/source')          ->to(controller => 'source', action => 'show' );
  $r->get('/ip')              ->to(controller => 'ip',     action => 'show' );
  $r->get('/ip/id/:id')       ->to(controller => 'ip',     action => 'id'   );
  $r->get('/ip/like/*match')  ->to(controller => 'ip',     action => 'match');
  $r->get('/ip/name/*name')   ->to(controller => 'ip',     action => 'name' );
  $r->get('/group')           ->to(controller => 'group',  action => 'show' );
  $r->get('/group/name/*name')->to(controller => 'group',  action => 'name' );
  $r->get('/grp/name/*name')  ->to(controller => 'group',  action => 'name' );

  $r->get('/service')         ->to(controller => 'service', action => 'show' );

  $r->get('/fwrule')          ->to(controller => 'fwrule', action => 'show' );

  $r->post('/ip/search')      ->to(controller => 'ip',     action => 'search' );
  $r->post('/group/search')   ->to(controller => 'group',  action => 'search' );

  $self->helper(n2ip => sub { Jemma::Utils::number_to_ip($_[1]) } );
  $self->helper(r2c  => sub { Jemma::Utils::range_to_cidr($_[1], $_[2]) } );
}

1;
