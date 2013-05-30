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

  my $schema = Jemma->schema;

  my @ip;
  for my $line ($schema->resultset('Ip')->search(
    {
      'me.name' => { like => "%$expr%" }
    },
    {
      prefetch => 'source',
      order_by => 'start',
    }
  )) {
    push @ip, $line;
  }
  $self->stash(ip => \@ip);

}

sub name {
  my $self = shift;
  my $name = $self->param('name');

  my $schema = Jemma->schema;

  $self->stash(ip => [
    $schema->resultset('Ip')->search(
      {
	'me.name' => $name,
      },
      {
	prefetch => 'source',
	order_by => 'start',
      }
    )]);

  my @group;
  for my $line ($schema->resultset('Ipgrp')->search(
    {
      'ip.name' => $name,
    },
    {
      prefetch => 'ip',
      order_by => 'ip.name',
    }
  )) {
    push @group, $line;
  }
  $self->stash(group => \@group);

}

1;
