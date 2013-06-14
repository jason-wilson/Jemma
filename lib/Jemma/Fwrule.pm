package Jemma::Fwrule;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;

  my $schema = Jemma->schema;

  $self->stash(fwrule => [
    $schema->resultset('Fwrule')->search( {},
      {
        prefetch => [ 'sourceset', 'destination' ],
	order_by => 'number',
      }
      )]);

  my %objs;
  for my $obj ($schema->resultset('Objectsetlist')->search(
      {
      },
      {
        prefetch => [ 'objectset', 'ip', 'grp' ],
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

1;
