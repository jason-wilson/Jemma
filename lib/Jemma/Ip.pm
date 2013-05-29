package Jemma::Ip;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;

  my $schema = Jemma->schema;

  my @ip;
  for my $line ($schema->resultset('Ip')->search(
    { },
    {
      prefetch => 'source',
      order_by => 'start',
    }
  )) {
    push @ip, $line;
  }

  $self->stash(ip => \@ip);
}

sub match {
  my $self = shift;
  my $expr = $self->param('match');

  print STDERR "Looking for IP's which match name '", $expr, "'\n";

  my $schema = Jemma->schema;

  my @ip;
  for my $line ($schema->resultset('Ip')->search(
    {
      'me.name' => { like => "%$expr%" }
    },
    {
      prefetch => 'source',
    }
  )) {
    push @ip, $line;
  }

  $self->stash(ip => \@ip);
}

1;

1;
