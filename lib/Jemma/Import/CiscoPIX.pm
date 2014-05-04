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
	  print "  Don't know what to do with $k and $v\n";
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
	  print "  Don't know what to do with $k and $v\n";
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

      $line = getline($fh);
      while ($line =~ /^ (\S+) (.*)/) {
        my ($k, $v) = ($1, $2);
	if ($k eq 'description') {
	  $o{description} = $v;
	  #print "  Set description to $v\n";
	} elsif ($k eq 'network-object') {
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
	  } elsif ($v =~ /^object (.*)/) {
	    push @ips, $db{ip}{$1}{id};
	  } else {
	    print "  Don't know what to with a v of $v\n";
	  }
	} elsif ($k eq 'group-object') {
	  push @grps, $db{group}{$v}{id};
	} else {
	  print "  Don't know what to do with $k and $v\n";
	}
	$line = getline($fh);
      }

      my $id = $schema->resultset('Grp')->create( {
        name        => $o{name},
	description => $o{description},
	source      => $db_source,
      });
      $db{group}{$o{name}}{id} = $id;

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

    if ($line =~ /^object-group service (.*)/) {
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
	    print "  Don't know what to with a v of '$v'\n";
	  }
	} elsif ($k eq 'group-object') {
	  push @grps, $db{svcgrp}{$v}{id};
	} else {
	  print "  Don't know what to do with $k and $v\n";
	}
	$line = getline($fh);
      }

      my $id = $schema->resultset('Servicegrp')->create( {
        name        => $o{name},
	description => $o{description},
	source      => $db_source,
      });
      $db{svcgrp}{$o{name}}{id} = $id;

      for (@svcs) {
	$schema->resultset('Servicegrpgrp')->create( {
	  servicegrp  => $id,
	  service     => $_,
	});
      }
      for (@grps) {
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

      my (@rest) = split /\s+/, $rest;
      my ($svc, $svc2, $src, $src2, $dst, $dst2);

      $svc = shift @rest;
      if ($svc eq 'object-group' or $svc eq 'object') {
        $svc2 = shift @rest;
      } else {
        $svc2 = 'any';
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

#      $svc = shift @rest;
#      if (! defined $svc) {
#	$svc = 'any';
#        $svc2 = 'any';
#      } elsif ($svc eq 'eq') {
#        $svc = shift @rest;
#	$svc2 //= 'n/a';
#      } else {
#	$svc2 = shift @rest;
#	$svc2 //= 'any';
#      }

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
      print "\n";

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

      if ($svc eq 'object-group') {
	$type = 'servicegrp';
        $id = $db{svcgrp}{$svc2}{id};
      } elsif ($svc eq 'object') {
	$type = 'service';
        $id = $db{service}{$svc2}{id};
      } else {
	$type = 'service';
	my $extra = shift @rest;
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
	  protocol => $svc,
	  source => $db_source })->id;
	$id = $db{service}{$svc}{id};
      }

      #print "Loading $svc_id $type $id\n";
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

      $rule_num++;
      #last if $rule_num > 20;

      $line = getline($fh);
      next;
    }

    print "Left with: $line\n";

    $line = getline($fh);
  }
}

1;

__DATA__

    if (/^name ([\d\.]+) (.*)/) {
      my ($ip, $name) = ($1, $2);
      my $desc = $name;

      if ($name =~ /(.*) description (.*)/) {
        $name = $1;
	$desc = $2;
      }

      my $ip_num = Jemma::Utils::ip_to_number($ip);

      my $id = $schema->resultset('Ip')->create( {
	start       => $ip_num,
	end         => $ip_num,
	name        => $name,
	description => $desc,
	source      => $source,
      });
      $db{ip}{$ip}{id} = $id;
      $db{ip}{$name}{id} = $id;
      next;
    }

    if (/^object-group service (.*)/) {
      # Found a new group, but dont create yet - see if we get a description
      $svcgrp = $1;
      $group = undef;
    }

    if (/^object-group network (.*)/) {
      # Found a new group, but dont create yet - see if we get a description
      $group = $1;
      $svcgrp = undef;
    }

    #print "    group=$group svcgrp=$svcgrp\n";

    if (defined $group and /^ description (.*)/) {
      #print " Create group $group\n";
      my $id = $schema->resultset('Grp')->create( {
        name        => $group,
	description => $1,
	source      => $source,
      });
      $db{group}{$group}{id} = $id;
    }

    if (defined $svcgrp and /^ description (.*)/) {
      my $desc = $1;
      my ($name, $proto) = split /\s+/, $svcgrp;
      #print " Create service group $name with $proto\n";
      my $id = $schema->resultset('Servicegrp')->create( {
        name        => $name,
	description => $desc,
	source      => $source,
      });
      $db{svcgrp}{$name}{id} = $id;
      $db{svcgrp}{$name}{proto} = $proto;
    }


    if (/^ port-object (.*)/) {
      my $service = $1;
      $service = $1 if $service =~ /^eq (.*)/;
      $service = join '-', $1, $2 if $service =~ /^range (\d+) (\d+)/;

      my ($name, $proto) = split /\s+/, $svcgrp;

      if (defined $svcgrp and ! defined $db{svcgrp}{$name}{id}) {
	my $id = $schema->resultset('Servicegrp')->create( {
	  name        => $name,
	  description => "$name over $proto",
	  source      => $source,
	});
	$db{svcgrp}{$name}{id} = $id;
	$db{svcgrp}{$name}{proto} = $proto;
      }

      my $id = $db{service}{$service}{id};
      if (! defined $id) {
	my $ports = $service =~ /^\d+$/ ? $service : 'unknown';
	$id = $schema->resultset('Service')->create( {
	  name      => $service,
	  protocol  => $db{svcgrp}{$name}{proto},
	  ports     => $ports,
	  source    => $source,
	});
	$db{service}{$service}{id} = $id;
      }

      $schema->resultset('Servicegrpgrp')->create( {
	servicegrp => $db{svcgrp}{$name}{id},
	service    => $id,
      });

    }

    if (/^ network-object / or /^ group-object / ) {

      if (defined $group and ! defined $db{group}{$group}{id}) {
	#print " Create new group: $group\n";
	my $id = $schema->resultset('Grp')->create( {
	  name        => $group,
	  description => "$group",
	  source      => $source,
	});
	$db{group}{$group}{id} = $id;
      }

      if (/^ network-object host ([\d\.]+)/) {
	my $ip = $1;
	my $id = $db{ip}{$ip}{id};
	if (! $id) {
	  #print " Create new host: $1\n";
	  my $num_ip = Jemma::Utils::ip_to_number($ip);
	  $id = $schema->resultset('Ip')->create( {
	    start       => $num_ip,
	    end         => $num_ip,
	    name        => $ip,
	    description => "$ip",
	    source      => $source,
	  });
	  $db{ip}{$ip}{id} = $id;
	}

	$schema->resultset('Ipgrp')->create( {
	  ip  => $id,
	  grp => $db{group}{$group}{id},
	});
      }

      if (defined $group and /^ group-object (\S+)/) {
	my $name = $1;
	#print "  Add sub-group $name to $group\n";

	$schema->resultset('Grpgrp')->create( {
	  parent  => $db{group}{$group}{id},
	  child   => $db{group}{$name}{id},
	});
      }

    }

    # Remember remark if there is one
    if (/^access-list \S+ remark (.*)/) {
      if (defined $remark) {
	$remark .= "\n" . $1;
      } else {
        $remark = $1;
      }
    }

    if (/^access-list (\S+) extended (\S+) (\S+) (.*)/) {
      # Got an ACL, with group name, action, protocol and rest of line
      my ($name, $action, $proto, $rest) = ($1, $2, $3, $4);
      if ($proto eq 'object-group') {
        warn "$rule_num: Don't support groups of protocols yet, fudging...\n";
	$proto = 'any';
	$rest =~ s:\S+\s::;
      }

      my (@rest) = split /\s+/, $rest;
      my ($src, $src2, $dst, $dst2, $svc, $svc2);

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
      } elsif ($svc eq 'eq') {
        $svc = shift @rest;
	$svc2 //= 'n/a';
      } else {
	$svc2 = shift @rest;
	$svc2 //= 'any';
      }

      my $disabled = 0;
      $disabled = 1 if / inactive$/;

      $remark //= "Rule number $rule_num";

      print "Name($rule_num): $name\n";
      print "  Action : $action\n";
      print "  Proto  : $proto\n";
      print "  Source : $src and $src2\n";
      print "  Dest   : $dst and $dst2\n";
      print "  Service: $svc and $svc2\n";
      print "  Remark : $remark\n";
      print "  Disable: $disabled\n";
      print "\n";

      my $src_id = $schema->resultset('Objectset')->create( {
	name => "src: $name", source => $source })->id;
      my $dst_id = $schema->resultset('Objectset')->create( {
	name => "dst: $name", source => $source })->id;
      my $svc_id = $schema->resultset('Objectset')->create( {
	name => "svc: $name", source => $source })->id;

      my ($type, $id);
      if ($src eq 'any') {
	$type = 'ip';
        $id = $db{ip}{any}{id};
      } elsif ($src eq 'object-group') {
	$type = 'grp';
        $id = $db{group}{$src2}{id};
      } elsif ($src eq 'host') {
        $type = 'ip';
	if (! defined $db{ip}{$src2}{id}) {
	  my $num_ip = Jemma::Utils::ip_to_number($src2);
	  $id = $schema->resultset('Ip')->create( {
	    start       => $num_ip,
	    end         => $num_ip,
	    name        => $src2,
	    description => "$src2",
	    source      => $source,
	  });
	  $db{ip}{$src2}{id} = $id;
	}
	$id = $db{ip}{$src2}{id};
      } elsif ($src =~ /^[\d\.]+$/) {
        $type = 'ip';
	my $name = $src . "/" . $src2;
	if (! defined $db{ip}{$name}{id}) {
	  my ($cidr) = Net::CIDR::addrandmask2cidr($src, $src2);
	  my ($start, $end) = Jemma::Utils::cidr_to_range($cidr);

	  $id = $schema->resultset('Ip')->create( {
	    start       => $start,
	    end         => $end,
	    name        => $name,
	    description => "$name",
	    source      => $source,
	  });
	  $db{ip}{$name}{id} = $id;
	}
	$id = $db{ip}{$name}{id};
      }

      die "No src id\n" unless defined $id;
      $schema->resultset('Objectsetlist')->create( {
        objectset => $src_id,
	type	  => $type,
	$type     => $id,
      } );

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
	    source      => $source,
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
	    source      => $source,
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

      if ($svc eq 'object-group') {
	$type = 'servicegrp';
        $id = $db{svcgrp}{$svc2}{id};
      } else {
	$type = 'service';
	$id = $db{service}{$svc}{id};
      }
      if (! defined $id) {
	$db{service}{$svc}{id} = $schema->resultset('Service')->create( {
	  name => $svc,
	  protocol => $proto,
	  source => $source })->id;
	$id = $db{service}{$svc}{id};
      }

      #print "Loading $svc_id $type $id\n";
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
	source      => $source,
	description => $remark,
	enabled     => !$disabled,
      });
      undef $remark;

      $rule_num++;
      #last if $rule_num > 10;

    }

    if (/^interface (.*)/) {
      # Found an interface - remember for later
      my $int = $1;
      my ($desc, $name, $ip, $mask, $ip2) = ('undefined');
      while (<$fh>) {
        last if /^!/;
	s/[\n\r]*$//;
	$desc = $1 if /^ description (.*)/;
	$name = $1 if /^ nameif (.*)/;
	if (/^ ip address ([\d\.]+) ([\d\.]+) standby ([\d\.]+)/) {
	  # Got an IP with a standby address
	  $ip = $1;
	  $mask = $2;
	  $ip2 = $3;
	}
	$ip = $1, $mask=$2 if /^ ip address ([\d\.]+) ([\d\.]+)$/;
      }
      next unless defined $ip;
      #print "Loading $int with '$desc' and $name with $ip/$mask and $ip2/$mask\n";
      $desc //= 'Interface ' . $int;

      for my $i ($ip, $ip2) {
        next unless defined $i;

	my $ip_num = Jemma::Utils::ip_to_number($i);

	$schema->resultset('Ip')->create( {
	  start       => $ip_num,
	  end         => $ip_num,
	  name        => 'Interface ' . $int,
	  description => $desc,
	  source      => $source,
	});
      }

      my $cidr = Net::CIDR::addrandmask2cidr($ip, $mask);
      my ($start, $end) = Jemma::Utils::cidr_to_range($cidr);
      $schema->resultset('Ip')->create( {
	start       => $start,
	end         => $end,
	name        => 'Network for interface ' . $int,
	description => $desc,
	source      => $source,
      });

    }
  } while defined $line;
}

1;
