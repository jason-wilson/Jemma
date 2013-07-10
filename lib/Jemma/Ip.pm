package Jemma::Ip;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;

  my $schema = Jemma->schema;

  my $source = $self->param('source');
  my @search;
  push @search, 'source.name', $source if defined $source;

  my @ip;
  for my $line ($schema->resultset('Ip')->search(
    {
      @search,
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

sub search {
  my $self = shift;
  my $ip = $self->param('ip');
  
  my $schema = Jemma->schema;

  if ($ip =~ /^[\d\.]+$/) {
    my $number = Jemma::Utils::ip_to_number($ip);
    print STDERR "Got $ip and gives us $number\n";

    $self->stash(ip => [
      $schema->resultset('Ip')->search(
	{
	  'start' => {'<=', $number},
	  'end'   => {'>=', $number},
	},
	{
	  prefetch => 'source',
	  order_by => 'start',
	}
      )]);
  } elsif ($ip =~ /^[\d\.]+\/\d+$/) {
    my ($start, $end) = Jemma::Utils::cidr_to_range($ip);

    $self->stash(ip => [
      $schema->resultset('Ip')->search(
	{
	  'start' => {'>=', $start},
	  'end'   => {'<=', $end},
	},
	{
	  prefetch => 'source',
	  order_by => 'start',
	}
      )]);

  } elsif ($ip =~ /[_%]/) {
    # Has 'like' type expressions

    $self->stash(ip => [
      $schema->resultset('Ip')->search(
	{
	  '-or' => {
	    'me.name' => {'like', $ip},
	    'me.description' => {'like', $ip},
	  }
	},
	{
	  prefetch => 'source',
	  order_by => 'start',
	}
      )]);
  } else {
    # Assume it is a name to look for

    $self->stash(ip => [
      $schema->resultset('Ip')->search(
	{
	  'LOWER(me.name)' => lc($ip),
	},
	{
	  prefetch => 'source',
	  order_by => 'start',
	}
      )]);
  }
}

sub id {
  my $self = shift;
  my $id = $self->param('id');
  
  my $schema = Jemma->schema;

  $self->stash(ip => $schema->resultset('Ip')->search( { id => $id } ));

  $self->stash(extra => [
    $schema->resultset('Ipextra')->search(
      {
	ip => $id,
      },
      {
	order_by => 'key',
      }
    )]);

  $self->stash(group => [
    $schema->resultset('Ipgrp')->search(
    {
      'ip' => $id,
    },
    {
      prefetch => 'ip',
      order_by => 'ip.name',
    }
  )]);

}

1;
