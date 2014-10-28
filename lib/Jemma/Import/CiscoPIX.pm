package Jemma::Import::CiscoPIX;
use Jemma::Utils;
use strict;

my %db;
my $db_source;
my $db_schema;
my $DEBUG = 0;

sub new {
  my ($class) = shift;
  $class = ref($class) if ref($class);

  my $self = { @_ };

  bless $self, $class;
}

sub getline
{
  my $fh = shift;
  my ($line) = $fh->getline;
  return undef unless defined $line;
  $line =~ s/[\n\r]+$//;
  return $line;
}

sub create_ip
{
  my (%i) = (@_);
  my (%o);
  for (keys %i) {
    $o{$_} = $i{$_} unless $_ =~ /^_/;
  }
  $o{source} = $db_source;

  if ($DEBUG) {
    print "Creating IP with:\n";
    for (sort keys %o) {
      print "  $_ => ", $o{$_}, "\n"
    };
  }
  my $id = $db_schema->resultset('Ip')->create( { %o } );
  $db{ip}{$i{name}}{id} = $id;
  return $id;
}

sub create_service
{
  my (%i) = (@_);
  my (%o);
  for (keys %i) {
    $o{$_} = $i{$_} unless $_ =~ /^_/;
  }
  $o{source} = $db_source;
  if ($DEBUG) {
    print "Creating Service with:\n";
    for (sort keys %o) {
      print "  $_ => ", $o{$_}, "\n"
    };
  }

  my $id = $db_schema->resultset('Service')->create( { %o } );
  return $id;
}

sub importdata {
  my ($self) = shift;
  my ($schema) = shift;
  my ($source) = shift;
  my ($file) = shift;

  $db_schema = $schema;
  $schema->resultset('Source')->search( { name => $source } )->delete_all;
  $db_source = $schema->resultset('Source')->find_or_create( { name => $source })->id;

  my $num;
  my $rule_num = 1;
  my $remark;
  my ($group, $svcgrp);
  
  my %o;

  $db{service}{icmp}{id} = create_service(name => "icmp", protocol => 'icmp');
  $db{service}{udp}{id} = create_service(name => "udp", protocol => 'udp');
  $db{service}{tcp}{id} = create_service(name => "tcp", protocol => 'tcp');
  $db{service}{ip}{id} = create_service(name => "ip", protocol => 'ip');

  $db{service}{any}{id} = create_service(
      name => "any",
      protocol => 'any',
    );

  $db{ip}{any}{id} = create_ip(
      start       => 0,
      end         => 256*256*256*256-1,
      name        => 'any',
      description => 'any',
    );

  open my $fh, '<', $file;
  my $line = getline($fh);
  while (defined $line) {
    #print $line, "\n";

    if ($line =~ /^name ([\d\.]+) (\S+)(.*)/) {
      $o{name} = $2;
      $o{start} = $o{end} = Jemma::Utils::ip_to_number($1);
      $o{_ip} = $1;
      my $desc = $3;
      if ($desc eq '') {
        $desc = 'Object ' . $o{name};
      } else {
        $desc =~ s/ description //;
      }
      $o{description} = $desc;
      my $id = $db{ip}{$o{name}}{id};
      $id //= create_ip(%o);
      $db{ip}{$o{_ip}}{id} = $id;
      $db{ip}{$o{name}}{id} = $id;

      $line = getline($fh);
      next;
    }

    if ($line =~ /^object network (.*)/) {
      undef %o;
      $o{name} = $1;
      $line = getline($fh);
      while ($line =~ /^ (\w+) (.*)/) {
        my ($k, $v) = ($1, $2);
	if ($k eq 'host') {
	  $o{start} = $o{end} = Jemma::Utils::ip_to_number($v);
	  $o{_ip} = $v;
	} elsif ($k eq 'subnet') {
	  my $cidr = Net::CIDR::addrandmask2cidr(split / /, $v);
	  ($o{start}, $o{end}) = Jemma::Utils::cidr_to_range($cidr);
	  $o{_ip} = $cidr;
	} elsif ($k eq 'description') {
	  $o{description} = $v;
	} else {
	  print "  ", __LINE__, ":$.: Don't know what to do with $k and $v\n";
	}
	$line = getline($fh);
      }
      my $id = $db{ip}{$o{name}}{id};
      $id //= create_ip(%o);
      $db{ip}{$o{_ip}}{id} = $id;
      next;
    }

    if ($line =~ /^object service (.*)/) {
      undef %o;
      $o{name} = $1;
      $line = getline($fh);
      while ($line =~ /^ (\S+) (.*)/) {
        my ($k, $v) = ($1, $2);
	if ($k eq 'service') {
	  if ($line =~ /(\S+) destination eq (\w+)/) {
	    $o{protocol} = $1;
	    $o{ports} = $2;
	  }
	} else {
	  print "  ", __LINE__, ":$.: Don't know what to do with $k and $v\n";
	}
	$line = getline($fh);
      }
      my $id = create_service(%o);
      $db{service}{$o{ports}}{id} = $id;
      $db{service}{$o{name}}{id} = $id;
      next;
    }

    if ($line =~ /^object-group network (.*)/) {
      undef %o;
      $o{name} = $1;
      my (@ips, @grps);
      print "Processing $1\n";

      $line = getline($fh);
      while ($line =~ /^ (\S+) (.*)/) {
        my ($k, $v) = ($1, $2);
	if ($k eq 'description') {
	  $o{description} = $v;
	  #print "  Set description to $v\n";
	} elsif ($k eq 'network-object') {
	  #print "  Network object of $k with $v\n";
	  if ($v =~ /^([\d\.]+) ([\d\.]+)/) {
	    my $cidr = Net::CIDR::addrandmask2cidr($1, $2);
	    my $id = $db{ip}{$cidr}{id};
	    my ($start, $end) = Jemma::Utils::cidr_to_range($cidr);
	    $id //= create_ip(
	      name  => $cidr,
	      start => $start,
	      end   => $end,
	      );
	    push @ips, $id;
	  } elsif ($v =~ /^host (.*)/) {

	    my $id = $db{ip}{$1}{id};
	    my $start = Jemma::Utils::ip_to_number($1);
	    $id //= create_ip(
	      name  => $1,
	      start => $start,
	      end   => $start,
	      );
	    push @ips, $db{ip}{$1}{id};
	  } elsif ($v =~ /^object (.*)/) {
	    push @ips, $db{ip}{$1}{id};
	  } else {
	    print "  ", __LINE__, ":$.: Don't know what to with a v of $v\n";
	  }
	} elsif ($k eq 'group-object') {
	  push @grps, $db{group}{$v}{id};
	} else {
	  print "  ", __LINE__, ":$.: Don't know what to do with $k and $v\n";
	}
	$line = getline($fh);
      }

      my $id = $schema->resultset('Grp')->create( {
        name        => $o{name},
	description => $o{description},
	source      => $db_source,
      });
      $db{group}{$o{name}}{id} = $id;

      print "Creating ", $o{name}, "\n";
      for (@ips) {
	$schema->resultset('Ipgrp')->create( {
	  ip  => $_,
	  grp => $id,
	});
      }

      for (@grps) {
	$schema->resultset('Grpgrp')->create( {
	  parent  => $id,
	  child   => $_,
	});
      }

      next;
    }

    if ($line =~ /^object-group service (\S+)/) {
      undef %o;
      $o{name} = $1;
      my (@svcs, @grps);

      $line = getline($fh);
      while ($line =~ /^ (\S+) (.*)/) {
        my ($k, $v) = ($1, $2);
	$v =~ s/\s*$//; # Strip trailing spaces
	if ($k eq 'description') {
	  $o{description} = $v;
	} elsif ($k eq 'service-object') {
	  if ($v =~ /(\S+) destination eq (\S+)/) {
	    my $name = $1 . '/'. $2;
	    my $id = $db{service}{$name}{id};
	    $id //= create_service(
	      name => $name,
	      protocol => $1,
	      ports => $2,
	    );
	    push @svcs, $id;
	    $db{service}{$name}{id} = $id;
	  } elsif ($v =~ /(\S+) destination range (\S+) (\S+)/) {
	    my $name = $1 . '/' . $2 . '-' . $3;
	    my $id = $db{service}{$name}{id};
	    $id //= create_service(
	      name => $name,
	      protocol => $1,
	      ports => $2 . '-' . $3,
	    );
	    push @svcs, $id;
	    $db{service}{$name}{id} = $id;
	    
	  } elsif ($v eq 'icmp') {
	    push @svcs, $db{service}{icmp}{id};
	  } else {
	    print "  ", __LINE__, ":$.: Don't know what to with a v of '$v'\n";
	  }
	} elsif ($k eq 'group-object') {
	  print "Pushing $v onto \@grps: which is ", $db{svcgrp}{$v}{id}, "\n";
	  push @grps, $db{svcgrp}{$v}{id};
	} else {
	  print "  ", __LINE__, ":$.: Don't know what to do with $k and $v\n";
	}
	$line = getline($fh);
      }

      my $id = $schema->resultset('Servicegrp')->create( {
        name        => $o{name},
	description => $o{description},
	source      => $db_source,
      });
      print "Added svcgrp of '", $o{name}, "' as $id\n";
      $db{svcgrp}{$o{name}}{id} = $id;

      for (@svcs) {
	$schema->resultset('Servicegrpgrp')->create( {
	  servicegrp  => $id,
	  service     => $_,
	});
      }
      for (@grps) {
	print "Adding group service object $_ to $id\n";
	$schema->resultset('Servicegrpservicegrp')->create( {
	  parent  => $id,
	  child   => $_,
	});
      }

      next;
    }

    if ($line =~ /^access-list (\S+) remark (.*)/) {
      if (defined $remark) {
	$remark .= "\n" . $2;
      } else {
        $remark = $2;
      }

      $line = getline($fh);
      next;
    }

    if ($line =~ /^access-list (\S+) extended (\S+) (.*)/) {
      #$DEBUG = 1;
      # Got an ACL, with group name, action, protocol and rest of line
      my ($name, $action, $rest) = ($1, $2, $3, $4);

      # Remove any loggign stuff at end for now
      $rest =~ s/ log.*$//;

      my (@rest) = split /\s+/, $rest;
      my ($proto, $svc, $svc2, $src, $src2, $dst, $dst2);

      $proto = shift @rest;
      if ($proto eq 'object-group' or $proto eq 'object') {
        $proto = shift @rest;
      } else {
        $proto = 'any';
      }

      $src = shift @rest;
      if ($src ne 'any') {
        $src2 = shift @rest;
      } else {
        $src2 = 'any';
      }

      $dst = shift @rest;
      if ($dst ne 'any') {
        $dst2 = shift @rest;
      } else {
        $dst2 = 'any';
      }

      $svc = shift @rest;
      if (! defined $svc) {
	$svc = 'any';
        $svc2 = 'any';
      } else {
	$svc2 = shift @rest;
	$svc2 //= 'any';
      }

      my $disabled = 0;
      $disabled = 1 if $line =~ / inactive$/;

      $remark //= "Rule number $rule_num";

      print "Name($rule_num): $name\n";
      print "  Rest   : $rest\n";
      print "  Action : $action\n";
      print "  Source : $src and $src2\n";
      print "  Dest   : $dst and $dst2\n";
      print "  Service: $svc and $svc2\n";
      print "  Remark : $remark\n";
      print "  Disable: $disabled\n";

      my $src_id = $schema->resultset('Objectset')->create( {
	name => "src: $name", source => $db_source })->id;
      my $dst_id = $schema->resultset('Objectset')->create( {
	name => "dst: $name", source => $db_source })->id;
      my $svc_id = $schema->resultset('Objectset')->create( {
	name => "svc: $name", source => $db_source })->id;

      my ($type, $id);
      if ($src eq 'any') {
	$type = 'ip';
        $id = $db{ip}{any}{id};
      } elsif ($src eq 'object-group') {
	$type = 'grp';
        $id = $db{group}{$src2}{id};
      } elsif ($src eq 'object') {
        $type = 'ip';
        $id = $db{ip}{$src2}{id};
      } elsif ($src eq 'host') {
        $type = 'ip';
	$id = $db{ip}{$src2 . "/32"}{id};
	if (! defined $id) {
	  my $num_ip = Jemma::Utils::ip_to_number($src2);
	  $id = create_ip(
	    start => $num_ip,
	    end   => $num_ip,
	    name  => $src2 . "/32",
	  );
	}
      } elsif ($src =~ /^[\d\.]+$/) {
        $type = 'ip';
	my ($cidr) = Net::CIDR::addrandmask2cidr($src, $src2);
	if (! defined $db{ip}{$cidr}{id}) {
	  my ($start, $end) = Jemma::Utils::cidr_to_range($cidr);

	  $id = create_ip(
	    start       => $start,
	    end         => $end,
	    name        => $cidr,
	    description => "$cidr",
	  );
	}
	$id = $db{ip}{$cidr}{id};
      } elsif (defined $db{ip}{$src}) {
        $type = 'ip';
	$id = $db{ip}{$src}{id};
      } else {
        print "What is a src of type $src ?\n";
      }

      die "No src id\n" unless defined $id;
      $schema->resultset('Objectsetlist')->create( {
        objectset => $src_id,
	type	  => $type,
	$type     => $id,
      } );

      if ($dst eq 'eq') {
        # This is a rule with a restricted source port, ignoring for now...
	# Actually, add to remark for now
	$remark .= '<br>NOTE: Restricted to source port ' . $dst2;
	$dst = shift @rest;
	$dst2 = shift @rest;
      }

      if ($dst eq 'any') {
	$type = 'ip';
        $id = $db{ip}{any}{id};
      } elsif ($dst eq 'object-group') {
	$type = 'grp';
        $id = $db{group}{$dst2}{id};
      } elsif ($dst eq 'host') {
        $type = 'ip';
	if (! defined $db{ip}{$dst2}{id}) {
	  my $num_ip = Jemma::Utils::ip_to_number($dst2);
	  $id = $schema->resultset('Ip')->create( {
	    start       => $num_ip,
	    end         => $num_ip,
	    name        => $dst2,
	    description => "$dst2",
	    source      => $db_source,
	  });
	  $db{ip}{$dst2}{id} = $id;
	}
	$id = $db{ip}{$dst2}{id};
      } elsif ($dst =~ /^[\d\.]+$/) {
        $type = 'ip';
	my $name = $dst . "/" . $dst2;
	if (! defined $db{ip}{$name}{id}) {
	  my ($cidr) = Net::CIDR::addrandmask2cidr($dst, $dst2);
	  my ($start, $end) = Jemma::Utils::cidr_to_range($cidr);

	  $id = $schema->resultset('Ip')->create( {
	    start       => $start,
	    end         => $end,
	    name        => $name,
	    description => "$name",
	    source      => $db_source,
	  });
	  $db{ip}{$name}{id} = $id;
	}
	$id = $db{ip}{$name}{id};
      }

      die "No dst id: $_\n" unless defined $id;
      $schema->resultset('Objectsetlist')->create( {
        objectset => $dst_id,
	type	  => $type,
	$type     => $id,
      } );

      $id = undef;
      if ($svc eq 'object-group') {
	$type = 'servicegrp';
        $id = $db{svcgrp}{$svc2}{id};
      } elsif ($svc eq 'object') {
	$type = 'service';
        $id = $db{service}{$svc2}{id};
      } elsif ($svc eq 'any') {
	$type = 'service';
        $id = $db{service}{any}{id};
      } elsif ($svc eq 'eq') {
	$type = 'service';
	$svc = $svc2;
        $id = $db{service}{$svc}{id};
      } else {
	$type = 'service';
	my $extra = $svc2;
	if (defined $extra) {
	  if ($extra eq 'eq') {
	    my $name = $svc . "/" . shift @rest;
	    $id = $db{service}{$name}{id};
	    $id //= create_service(
	      name => $name,
	      protocol => $svc,
	      ports => $svc2,
	    );
	  } elsif ($extra eq 'range') {
	    my $from = shift @rest;
	    my $to = shift @rest;
	    my $name = $svc . "/" . $from . '-' . $to;
	    $id = $db{service}{$name}{id};
	    $id //= create_service(
	      name => $name,
	      protocol => $svc,
	      ports => $svc2,
	    );
	  } elsif ($extra eq 'echo-reply') {
	    $id = $db{service}{$svc}{id};
	  } else {
	    print "Have a service with $extra\n";
	  }
	} else {
	  $id = $db{service}{$svc}{id};
	}
      }

      if (! defined $id) {
	$db{service}{$svc}{id} = $schema->resultset('Service')->create( {
	  name => $svc,
	  protocol => $proto,
	  source => $db_source })->id;
	$id = $db{service}{$svc}{id};
      }

      $schema->resultset('Objectsetlist')->create( {
        objectset => $svc_id,
	type	  => $type,
	$type     => $id,
      } );

      # And finally create the actual rule
      $schema->resultset('Fwrule')->create( {
	number      => $rule_num,
	name        => $name,
	action      => $action,
	sourceset   => $src_id,
	destination => $dst_id,
	service     => $svc_id,
	source      => $db_source,
	description => $remark,
	enabled     => !$disabled,
      });
      undef $remark;
      print "\n";

      $rule_num++;
      #last if $rule_num > 2;

      $line = getline($fh);
      next;
    }

    print "Left with: $line\n";

    $line = getline($fh);
  }
}

1;
