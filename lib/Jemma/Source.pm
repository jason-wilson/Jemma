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
    $groups[$grp->source->id] = $grp->get_column('howmany');
  }
  $self->stash(groups => \@groups );

  my @services;
  for my $svc ($schema->resultset('Service')->search(
      {
      },
      {
	select => [ 'source', { count => 'source', -as => 'howmany' } ],
	group_by => 'source',
	order_by => 'source',
      },
    )) {
    $services[$svc->source->id] = $svc->get_column('howmany');
  }
  $self->stash(services => \@services );

  my @svcgrps;
  for my $svc ($schema->resultset('Servicegrp')->search(
      {
      },
      {
	select => [ 'source', { count => 'source', -as => 'howmany' } ],
	group_by => 'source',
	order_by => 'source',
      },
    )) {
    $svcgrps[$svc->source->id] = $svc->get_column('howmany');
  }
  $self->stash(svcgrps => \@svcgrps );

  my @fwrules;
  for my $fw ($schema->resultset('Fwrule')->search(
      {
      },
      {
	select => [ 'source', { count => 'source', -as => 'howmany' } ],
	group_by => 'source',
	order_by => 'source',
      },
    )) {
    $fwrules[$fw->source->id] = $fw->get_column('howmany');
  }
  $self->stash(fwrules => \@fwrules );

}

1;
