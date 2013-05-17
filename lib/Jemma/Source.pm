package Jemma::Source;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;

  my $schema = Jemma->schema;

  my @sources;
  for my $line ($schema->resultset('Source')->all) {
    push @sources, $line;
  }

  $self->stash(sources => \@sources);
}

1;
