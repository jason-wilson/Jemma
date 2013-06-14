package Jemma::Fwrule;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;

  my $schema = Jemma->schema;

  $self->stash(fwrule => [
    $schema->resultset('Fwrule')->all ]);

  my %objs;
  for my $obj ($schema->resultset('Objectsetlist')->search(
      {
      },
      {
        prefetch => 'objectset',
      }
    )) {
    my $type = $obj->type;

    if (defined $type and defined $obj->$type ) {
      $objs{$obj->objectset->id}{$obj->$type->name} = $type;
    } else {
      warn "Can't load $obj->id\n";
    }
  }
  $self->stash(objs => \%objs);

}

1;
