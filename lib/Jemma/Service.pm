package Jemma::Service;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;

  my $schema = Jemma->schema;

  $self->stash(service => [
    $schema->resultset('Service')->search(
    { },
    {
      prefetch => 'source',
      order_by => 'me.name',
    }
  )]);
}

sub name {
  my $self = shift;
  my $name = $self->param('name');

  my $schema = Jemma->schema;

  $self->stash(service => [
    $schema->resultset('Service')->search(
    {
      'me.name' => $name,
    },
    {
      prefetch => 'source',
      order_by => 'me.name',
    }
  )]);

  $self->stash(fwrule => [
    $schema->resultset('Fwrule')->search(
    {
      'service_2.name' => $name,
    },
    {
      join     => { service => { 'objectsetlists' => 'service' } },
      prefetch => "service",
      order_by => 'me.number',
    }
  )]);

  my %objs;
  for my $obj ($schema->resultset('Objectsetlist')->search(
      {
      },
      {
        prefetch => [ 'objectset', 'ip', 'grp', 'service', 'servicegrp' ],
      }
    )) {
    my $type = $obj->type;
    die "Has no type\n" unless defined $type;

    if ($type eq 'any') {
      $objs{$obj->objectset->id}{'any'} = 'ip';
    } else {
      $objs{$obj->objectset->id}{$obj->$type->name} = $type;
    }

  }
  $self->stash(objs => \%objs);
}

sub search {
  my $self = shift;
  my $name = $self->param('service');

  my $schema = Jemma->schema;

  $self->stash(service => [
    $schema->resultset('Service')->search(
    {
      '-or' => {
	'me.name'        => { like => $name },
	'me.description' => { like => $name },
      }
    },
    {
      prefetch => 'source',
      order_by => 'me.name',
    }
  )]);

}

1;
