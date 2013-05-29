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

1;
