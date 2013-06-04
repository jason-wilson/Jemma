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

sub search {
  my $self = shift;
  my $schema = Jemma->schema;
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
