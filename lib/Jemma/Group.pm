package Jemma::Group;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;
  my $schema = Jemma->schema;

  my @group;
  for my $line ($schema->resultset('Grp')->search(
    { },
    {
      prefetch => 'source',
      order_by => 'me.name',
    }
  )) {
    push @group, $line;
  }

  $self->stash(group => \@group);
}

sub name {
  my $self = shift;
  my $schema = Jemma->schema;
  my $name = $self->stash('name');

  my @ip;
  for my $line ($schema->resultset('Ipgrp')->search(
    { 
      'grp.name' => $name,
    },
    {
      prefetch => [ 'grp', 'ip' ],
      order_by => [ 'ip.source', 'grp.name' ],
    }
  )) {
    push @ip, $line;
  }
  $self->stash(ip => \@ip);

  my @parent;
  for my $line ($schema->resultset('Grpgrp')->search(
    { 
      'child.name' => $name,
    },
    {
      prefetch => [ 'parent', 'child' ],
      order_by => [ 'parent.name' ],
    }
  )) {
    push @parent, $line;
  }
  $self->stash(parent => \@parent);

  my @child;
  for my $line ($schema->resultset('Grpgrp')->search(
    { 
      'parent.name' => $name,
    },
    {
      prefetch => [ 'parent', 'child' ],
      order_by => [ 'child.name' ],
    }
  )) {
    push @child, $line;
  }
  $self->stash(child => \@child);

}

1;
