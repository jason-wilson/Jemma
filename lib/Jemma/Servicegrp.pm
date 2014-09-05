package Jemma::Servicegrp;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;
  my $schema = new Jemma->schema;

  my @svcgrp;
  for my $line ($schema->resultset('Servicegrp')->search(
    { },
    {
      prefetch => 'source',
      order_by => 'me.name',
    }
  )) {
    push @svcgrp, $line;
  }

  $self->stash(svcgrp => \@svcgrp);
}

sub name {
  my $self = shift;
  my $schema = new Jemma->schema;
  my $name = $self->stash('name');

  my @svc;
  for my $line ($schema->resultset('Servicegrpgrp')->search(
    { 
      'servicegrp.name' => $name,
    },
    {
      prefetch => [ 'servicegrp' ],
    }
  )) {
    push @svc, $line;
  }
  $self->stash(svc => \@svc);

}

sub search {
  my $self = shift;
  my $schema = new Jemma->schema;
  my $group = $self->param('group');

  if ($group =~ /[_%]/) {
    $self->stash(group => [
      $schema->resultset('Grp')->search(
      {
        'me.name' => {'like', $group},
      },
      {
	prefetch => 'source',
	order_by => 'me.name',
      },
    )]);
  } else {
    $self->stash(group => [
      $schema->resultset('Grp')->search(
      {
        'LOWER(me.name)' => lc($group),
      },
      {
	prefetch => 'source',
	order_by => 'me.name',
      },
    )]);
  }
}

1;
