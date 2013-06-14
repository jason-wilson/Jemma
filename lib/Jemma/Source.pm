package Jemma::Source;
use Mojo::Base 'Mojolicious::Controller';
use Jemma::Schema;

sub show {
  my $self = shift;

  my $schema = Jemma->schema;

  $self->stash(sources => [
    $schema->resultset('Source')->all ]);

  my @ips;
  for my $ip ($schema->resultset('Ip')->search(
      {
      },
      {
	select => [ 'source', { count => 'source', -as => 'howmany' } ],
	group_by => 'source',
	order_by => 'source',
      },
    )) {
    $ips[$ip->source->id] = $ip->get_column('howmany');
  }
  $self->stash(ips => \@ips );

  my @groups;
  for my $grp ($schema->resultset('Grp')->search(
      {
      },
      {
	select => [ 'source', { count => 'source', -as => 'howmany' } ],
	group_by => 'source',
	order_by => 'source',
      },
    )) {
    print "grp is $grp\n";
    $groups[$grp->source->id] = $grp->get_column('howmany');
  }
  $self->stash(groups => \@groups );

}

1;
