package Jemma::Natrule;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;

  my $schema = new Jemma->schema;

  my $source = $self->param('source');
  my @search;
  push @search, 'source.name', $source if defined $source;

  $self->stash(natrule => [
    $schema->resultset('Natrule')->search(
      {
        @search,
      },
      {
        prefetch => [ 'source',
	              'origsrcset', 'origdstset', 'origsvcset',
	              'natsrcset', 'natdstset', 'natsvcset',
		      ],
	order_by => 'number',
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

    #print join ' ', 'obj', $obj, '(' . $obj->id . ')', 'has type', $type, "\n";
    #print join ' ', 'obj', $obj, '(' . $obj->id . ')', 'has type', $type, 'and name', $obj->$type->name, "\n";
    if ($type eq 'any') {
      $objs{$obj->objectset->id}{'any'} = 'ip';
    } else {
      $objs{$obj->objectset->id}{$obj->$type->name} = $type;
    }

  }
  $self->stash(objs => \%objs);

}

1;
