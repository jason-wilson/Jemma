package Jemma::Import::CiscoPIX;
use Jemma::Utils;
use strict;

sub new {
  my ($class) = shift;
  $class = ref($class) if ref($class);

  my $self = { @_ };

  bless $self, $class;
}

sub importdata {
  my ($self) = shift;
  my ($schema) = shift;
  my ($source) = shift;
  my ($file) = shift;

  $schema->resultset('Source')->search( { name => $source } )->delete_all;
  $source = $schema->resultset('Source')->find_or_create( { name => $source })->id;

  my %db;
  my $num;
  my $rule_num = 1;
  my ($group, $svcgrp);

  $db{service}{any}{id} = $schema->resultset('Service')->create( {
    name => "any",
    protocol => 'any',
    source => $source })->id;

  $db{ip}{any}{id} = $schema->resultset('Ip')->create( {
    start       => 0,
    end         => 256*256*256*256,
    name        => 'any',
    description => 'any',
    source      => $source })->id;

  open my $fh, '<', $file;
  while (<$fh>) {
    s/[\n\r]+$//;
    #print "$_\n";

    if (/^name ([\d\.]+) (.*)/) {
      my ($ip, $name) = ($1, $2);

      $ip = Jemma::Utils::ip_to_number($ip);

      my $id = $schema->resultset('Ip')->create( {
	start       => $ip,
	end         => $ip,
	name        => $name,
	description => "$name",
	source      => $source,
      });
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
      print " Create group $group\n";
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
      print " Create service group $name with $proto\n";
      my $id = $schema->resultset('Servicegrp')->create( {
        name        => $name,
	description => $desc,
	source      => $source,
      });
      $db{svcgrp}{$svcgrp}{id} = $id;
      $db{svcgrp}{$svcgrp}{proto} = $proto;
    }


    if (/^ port-object eq (.*)/) {
      my $service = $1;

      if (defined $svcgrp and ! defined $db{svcgrp}{$svcgrp}{id}) {
	my ($name, $proto) = split /\s+/, $svcgrp;
	my $id = $schema->resultset('Servicegrp')->create( {
	  name        => $name,
	  description => "$name over $proto",
	  source      => $source,
	});
	$db{svcgrp}{$svcgrp}{id} = $id;
	$db{svcgrp}{$svcgrp}{proto} = $proto;
      }

      my $id = $db{service}{$service}{id};
      if (! defined $id) {
	my $ports = $service =~ /^\d+$/ ? $service : 'unknown';
	$id = $schema->resultset('Service')->create( {
	  name      => $service,
	  protocol  => $db{svcgrp}{$svcgrp}{proto},
	  ports     => $ports,
	  source    => $source,
	});
	$db{service}{$service}{id} = $id;
      }

      $schema->resultset('Servicegrpgrp')->create( {
	servicegrp => $db{svcgrp}{$svcgrp}{id},
	service    => $id,
      });

    }

    if (/^ network-object / or /^ group-object / ) {

      if (defined $group and ! defined $db{group}{$group}{id}) {
	print " Create new group: $group\n";
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
	  print " Create new host: $1\n";
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
	print "  Add sub-group $name to $group\n";

	$schema->resultset('Grpgrp')->create( {
	  parent  => $db{group}{$group}{id},
	  child   => $db{group}{$name}{id},
	});
      }

    }

    if (/^access-list (\S+) extended (\w+) (\w+) (.*)/) {
      # Got an ACL, with group name, action, protocol and rest of line
      my ($name, $action, $proto, $rest) = ($1, $2, $3, $4);

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
      } else {
        $svc2 = shift @rest;
      }

      print "Name: $name\n";
      print "  Action : $action\n";
      print "  Proto  : $proto\n";
      print "  Source : $src and $src2\n";
      print "  Dest   : $dst and $dst2\n";
      print "  Service: $svc and $svc2\n";
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

      die "No dst id\n" unless defined $id;
      $schema->resultset('Objectsetlist')->create( {
        objectset => $dst_id,
	type	  => $type,
	$type     => $id,
      } );

      $schema->resultset('Fwrule')->create( {
	number      => $rule_num,
	name        => $name,
	action      => $action,
	sourceset   => $src_id,
	destination => $dst_id,
	service     => $svc_id,
	source      => $source,
      });

      $rule_num++;


    }

    if (/^set policy id (\d+) name "([^"]*)" from "([^"]*)" to "([^"]*)"  "([^"]*)" "([^"]*)" "([^"]*)" (.+)/) {
      $num = $1;
      my ($name, $szone, $dzone, $src, $dst, $service, $action) = ($2, $3, $4, $5, $6, $7, $8);
      $db{rule}{$rule_num}{name} = $name;
      $db{rule}{$rule_num}{src}{$src}++;
      $db{rule}{$rule_num}{dst}{$dst}++;
      $db{rule}{$rule_num}{service}{$service}++;
      $db{rule}{$rule_num}{action} = $action;
      next;
    }

    if (/^set policy id (\d+) from "([^"]*)" to "([^"]*)"  "([^"]*)" "([^"]*)" "([^"]*)" (.+)/) {
      $num = $1;
      my ($szone, $dzone, $src, $dst, $service, $action) = ($2, $3, $4, $5, $6, $7);
      $db{rule}{$rule_num}{name} = "Rule id $num";
      $db{rule}{$rule_num}{src}{$src}++;
      $db{rule}{$rule_num}{dst}{$dst}++;
      $db{rule}{$rule_num}{service}{$service}++;
      $db{rule}{$rule_num}{action} = $action;
      next;
    }
    next if /^set policy id (\d+)$/;

    if (defined $num) {
      $num = undef, $rule_num++, next if /^exit/;
      $db{rule}{$rule_num}{disable}++,     next if /^set policy id (\d+) disable$/;
      $db{rule}{$rule_num}{src}{$1}++,     next if /^set src-address "([^"]*)"/;
      $db{rule}{$rule_num}{dst}{$1}++,     next if /^set dst-address "([^"]*)"/;
      $db{rule}{$rule_num}{service}{$1}++, next if /^set service "([^"]*)"/;
      warn "Try: $_\n";
    }

    if (/^set route ([\d\.\/]+) interface (\w+) gateway ([\d\.]+)/) {
      my ($ip, $intf, $gw) = ($1, $2, $3);
      print "Add $ip through $intf to $gw\n";

      my ($start, $end) = Jemma::Utils::cidr_to_range($ip);
      $gw = Jemma::Utils::ip_to_number($gw);

      my $id = $schema->resultset('Route')->create( {
	start       => $start,
	end         => $end,
	interface   => $intf,
	gateway     => $gw,
	metric      => 0,
	source      => $source,
      });
    }

  }

  for my $r (keys %{$db{rule}}) {

    my $src_id = $schema->resultset('Objectset')->create( {
      name => "src: $r", source => $source })->id;
    my $dst_id = $schema->resultset('Objectset')->create( {
      name => "dst: $r", source => $source })->id;
    my $svc_id = $schema->resultset('Objectset')->create( {
      name => "svc: $r", source => $source })->id;

    for (keys %{$db{rule}{$r}{src}} ) {
      my ($type, $id);

      if (defined $db{ip}{$_}{id}) {
        $type = 'ip';
	$id = $db{ip}{$_}{id};
      }
      if (defined $db{group}{$_}{id}) {
        $type = 'grp';
	$id = $db{group}{$_}{id};
      }

      die "Unknown type in rule $r for name '$_'\n" unless defined $type;

      $schema->resultset('Objectsetlist')->create( {
        objectset => $src_id,
	type	  => $type,
	$type     => $id,
      } );

    }

    for (keys %{$db{rule}{$r}{dst}} ) {
      my ($type, $id);

      if (/^VIP\((.*)\)/) {
	my $ip = $1;
	my $start = Jemma::Utils::ip_to_number($ip);
	my $id = $schema->resultset('Ip')->create( {
	  start       => $start,
	  end         => $start,
	  name        => $_,
	  description => "VIP $ip",
	  source      => $source,
	});
	$db{ip}{$_}{id} = $id;
      }

      if (defined $db{ip}{$_}{id}) {
        $type = 'ip';
	$id = $db{ip}{$_}{id};
      }
      if (defined $db{group}{$_}{id}) {
        $type = 'grp';
	$id = $db{group}{$_}{id};
      }

      die "Unknown type in rule $r for name '$_'\n" unless defined $type;
      $schema->resultset('Objectsetlist')->create( {
        objectset => $dst_id,
	type	  => $type,
	$type     => $id,
      } );
    }

    for (keys %{$db{rule}{$r}{service}} ) {
      my $type = 'service';
      my $id = $db{service}{$_}{id};

      if (! defined $id) {
	$db{service}{$_}{id} = $schema->resultset('Service')->create( {
	  name => $_,
	  protocol => 'tcp',
	  source => $source })->id;
	$id = $db{service}{$_}{id};
      }

      $schema->resultset('Objectsetlist')->create( {
        objectset => $svc_id,
	type	  => $type,
	$type     => $id,
      } );
    }

    $schema->resultset('Fwrule')->create( {
      number      => $r,
      name        => $db{rule}{$r}{name},
      action      => $db{rule}{$r}{action},
      sourceset   => $src_id,
      destination => $dst_id,
      service     => $svc_id,
      source      => $source,
    });
  }

}

1;
