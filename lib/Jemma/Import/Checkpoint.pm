package Jemma::Import::Checkpoint;
use Jemma::Utils;
use strict;
use Data::Dumper;

$Data::Dumper::Indent = 1;

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
  my ($objects) = shift;
  my ($rulebase) = shift;

  $schema->resultset('Source')->search( { name => $source } )->delete_all;
  $source = $schema->resultset('Source')->find_or_create( { name => $source })->id;

  my @d;
  $d[0] = 'ckp';
  my %data;
  my %d;
  my @rule;

  for my $file ($objects, $rulebase) {

    my $rule_num = 0;
    my $nat_num = 0;
    #
    # Remember ReferenceObject count
    my $refnum = 0;

    print "Loading $file data\n";
    open my $fh, '<', $file;
    while (<$fh>) {
      s/[\n\r]+$//;


      # Count how many tabs at start of line
      my ($idx) = s/\t//g;
      next unless $idx > 0;

      # Make sure array is only as big as current size
      @d = @d[0 .. $idx];

      if ( /:rule \($/ ) {
        $d[$idx] = sprintf '_rule %04d', ++$rule_num;
	next;
      }
      if ( /:rule_adtr \($/ ) {
        $d[$idx] = sprintf '_nat %04d', ++$nat_num;
	next;
      }

      if ( /:(\S+) \((.*)\)/ ) {
	$d[$idx] = $1;
	my $val = $2;
	$val =~ s/^"//;
	$val =~ s/"$//;

	#print $idx, ": ", join ('->', @d[1 .. $#d]), '=', $val, "\n";

	# Ugly - but is there a better way?
	$d{$d[1]}                                                  = $val if $idx == 1;
	$d{$d[1]}{$d[2]}                                           = $val if $idx == 2;
	$d{$d[1]}{$d[2]}{$d[3]}                                    = $val if $idx == 3;
	$d{$d[1]}{$d[2]}{$d[3]}{$d[4]}                             = $val if $idx == 4;
	$d{$d[1]}{$d[2]}{$d[3]}{$d[4]}{$d[5]}                      = $val if $idx == 5;
	$d{$d[1]}{$d[2]}{$d[3]}{$d[4]}{$d[5]}{$d[6]}               = $val if $idx == 6;
	$d{$d[1]}{$d[2]}{$d[3]}{$d[4]}{$d[5]}{$d[6]}{$d[7]}        = $val if $idx == 7;
	$d{$d[1]}{$d[2]}{$d[3]}{$d[4]}{$d[5]}{$d[6]}{$d[7]}{$d[8]} = $val if $idx == 8;
	$d{$d[1]}{$d[2]}{$d[3]}{$d[4]}{$d[5]}{$d[6]}{$d[7]}{$d[8]}{$d[9]} = $val if $idx == 9;

	next;
      }

      if ( /: \((.*)/ ) {
	if ($1 eq 'ReferenceObject') {
	  $d[$idx] = '_ref ' . $refnum++;
	} else {
	  $d[$idx] = $1;
	}
	next;
      }

      if ( /:(\S+) \((.*)/ ) {
	$d[$idx] = $1;
	$d[$idx+1] = $2;
	next;
      }

    }
    close $fh;
  }

  #print Data::Dumper->Dump([\%d], [qw(d)]);
 
  # Load predefined objects that we might need
  my $uid = $d{globals}{Any}{AdminInfo}{chkpf_uid};
  $d{_uid}{$uid}{type} = 'ip';
  $d{_uid}{$uid}{id} = $schema->resultset('Ip')->create( {
    start       => 0,
    end         => 256*256*256*256-1,
    name        => 'Any',
    description => 'Any',
    source      => $source })->id;

  # Load hosts and subnet's first
  for my $host (keys %{$d{network_objects}}) {
    my $h = $d{network_objects}{$host};
    next if $host eq 'DAG_range'; #Ignore this pre-defined for now

    if (exists $h->{ipaddr}) {
      if (exists $h->{netmask}) {

	my $cidr = Net::CIDR::addrandmask2cidr(
	  $h->{ipaddr},
	  $h->{netmask},
	);

	my ($start, $end) = Jemma::Utils::cidr_to_range($cidr);

	my $id = $schema->resultset('Ip')->create( {
	  start       => $start,
	  end         => $end,
	  name        => $host,
	  description => $h->{comments},
	  source      => $source,
	});
	$d{_uid}{$h->{AdminInfo}{chkpf_uid}}{type} = 'ip';
	$d{_uid}{$h->{AdminInfo}{chkpf_uid}}{id} = $id->id;
      } else {
	my $number = Jemma::Utils::ip_to_number($h->{ipaddr});
	my $id = $schema->resultset('Ip')->create( {
	  start       => $number,
	  end         => $number,
	  name        => $host,
	  description => $h->{comments},
	  source      => $source,
	});
	$d{_uid}{$h->{AdminInfo}{chkpf_uid}}{type} = 'ip';
	$d{_uid}{$h->{AdminInfo}{chkpf_uid}}{id} = $id->id;
      }
    } elsif (exists $h->{ipaddr_first}) {
      my ($start) = Jemma::Utils::ip_to_number($h->{ipaddr_first});
      my ($end)   = Jemma::Utils::ip_to_number($h->{ipaddr_last});

      my $id = $schema->resultset('Ip')->create( {
	start       => $start,
	end         => $end,
	name        => $host,
	description => $h->{comments},
	source      => $source,
      });
      $d{_uid}{$h->{AdminInfo}{chkpf_uid}}{type} = 'ip';
      $d{_uid}{$h->{AdminInfo}{chkpf_uid}}{id} = $id->id;
    }

    if (defined $d{_uid}{$h->{AdminInfo}{chkpf_uid}}{id}) {
      #
      # We just created the object, now load extras
      $schema->resultset('Ipextra')->create( {
        ip => $d{_uid}{$h->{AdminInfo}{chkpf_uid}}{id},
	key => 'color',
	value => $h->{color},
	source => $source,
      });

      if (defined $h->{valid_ipaddr} and $h->{valid_ipaddr} ne '') {
	$schema->resultset('Ipextra')->create( {
	  ip => $d{_uid}{$h->{AdminInfo}{chkpf_uid}}{id},
	  key => 'nat',
	  value => $h->{valid_ipaddr},
	  source => $source,
	});

	my ($start) = Jemma::Utils::ip_to_number($h->{valid_ipaddr});

	$schema->resultset('Ip')->create( {
	  start       => $start,
	  end         => $start,
	  name        => 'Automatic NAT for ' . $host,
	  description => 'Automatic NAT for ' . $host,
	  source      => $source,
	});
      }

    }

    # Look for extra interfaces on object and create those
    if (ref($h->{interfaces}) eq 'HASH') {
      for my $int (sort keys %{$h->{interfaces}}) {
	my $name = $h->{interfaces}{$int}{officialname};
	print $host, " has a $name interface\n";

	my ($ip) = Jemma::Utils::ip_to_number($h->{interfaces}{$int}{ipaddr});
	$schema->resultset('Ip')->create( {
	  start       => $ip,
	  end         => $ip,
	  name        => 'Interface ' . $name . ' on ' . $host,
	  description => 'Interface ' . $name . ' on ' . $host,
	  source      => $source,
	});

	my $cidr = Net::CIDR::addrandmask2cidr(
	  $h->{interfaces}{$int}{ipaddr},
	  $h->{interfaces}{$int}{netmask},
	);

	my ($start, $end) = Jemma::Utils::cidr_to_range($cidr);

	my $id = $schema->resultset('Ip')->create( {
	  start       => $start,
	  end         => $end,
	  name        => "Network on interface " . $name . ' on ' . $host,
	  description => "Network on interface " . $name . ' on ' . $host,
	  source      => $source,
	});



      }
    }
  }
  
  # Load services
  for my $svc (keys %{$d{services}}) {
    my $s = $d{services}{$svc};

    my $id = $schema->resultset('Service')->create( {
      name      => $svc,
      protocol  => $s->{type},
      ports     => $s->{port},
      source    => $source,
      });
    $d{_uid}{$s->{AdminInfo}{chkpf_uid}}{type} = 'service';
    $d{_uid}{$s->{AdminInfo}{chkpf_uid}}{id} = $id->id;
  }

  # Load all groups first to resolve back references
  for my $group (keys %{$d{network_objects}}) {
    my $g = $d{network_objects}{$group};

    if (exists $g->{type} and $g->{type} eq 'group') {
      my ($gid) = $schema->resultset('Grp')->create( {
	name        => $group,
	description => $g->{comments},
	source      => $source,
      });
      $d{_uid}{$g->{AdminInfo}{chkpf_uid}}{type} = 'grp';
      $d{_uid}{$g->{AdminInfo}{chkpf_uid}}{id} = $gid->id;
    }
  }

  # Link to members
  for my $group (keys %{$d{network_objects}}) {
    my $g = $d{network_objects}{$group};

    if (exists $g->{type} and $g->{type} eq 'group') {
      for my $ref (keys $g) {
	next unless $ref =~ /^_ref /;

	my ($my_id) = $d{_uid}{$g->{AdminInfo}{chkpf_uid}}{id};
	my ($type) = $d{_uid}{$g->{$ref}{Uid}}{type};
	my ($id) = $d{_uid}{$g->{$ref}{Uid}}{id};

	die "Unknown type for $ref\n" unless defined $type;

	if ($type eq 'ip') {
	  $schema->resultset('Ipgrp')->create( {
	    grp => $my_id,
	    ip  => $id,
	  });
	} elsif ($type eq 'grp') {
	  $schema->resultset('Grpgrp')->create( {
	    parent => $my_id,
	    child  => $id,
	  });
	} else {
	  die "Don't know how to link type $type\n";
	}
      }
    }
  }

  #print Data::Dumper->Dump([\%d], [qw(d)]);
  
  for my $r (sort keys %{$d{'rule-base'}}) {
    next unless $r =~ /^_rule (\d+)/;

    my $rule_num = $1 + 0;

    my $rule = $d{'rule-base'}{$r};
    my $action = $rule->{action}{accept}{type};
    $action //= $rule->{action}{drop}{type};
    $action //= $rule->{action}{reject}{type};

    my $src_id = $schema->resultset('Objectset')->create( {
      name => "src: $rule_num", source => $source })->id;
    my $dst_id = $schema->resultset('Objectset')->create( {
      name => "dst: $rule_num", source => $source })->id;
    my $svc_id = $schema->resultset('Objectset')->create( {
      name => "svc: $rule_num", source => $source })->id;

    for my $src (grep /^_ref /, keys %{$rule->{src}}) {
      my $uid = $rule->{src}{$src}{Uid};
      my $type = $d{_uid}{$uid}{type};

      $schema->resultset('Objectsetlist')->create( {
        objectset => $src_id,
	type      => $type,
	$type     => $d{_uid}{$uid}{id},
      });
    }

    for my $dst (grep /^_ref /, keys %{$rule->{dst}}) {
      my $uid = $rule->{dst}{$dst}{Uid};
      my $type = $d{_uid}{$uid}{type};

      $schema->resultset('Objectsetlist')->create( {
        objectset => $dst_id,
	type      => $type,
	$type     => $d{_uid}{$uid}{id},
      });
    }

    for my $svc (grep /^_ref /, keys %{$rule->{services}}) {
      my $uid = $rule->{services}{$svc}{Uid};
      my $type = $d{_uid}{$uid}{type};

      $schema->resultset('Objectsetlist')->create( {
        objectset => $svc_id,
	type      => $type,
	$type     => $d{_uid}{$uid}{id},
      });
    }

    my $track = 'unknown';
    for my $t (grep /^_ref /, keys %{$rule->{track}}) {
      $track = $rule->{track}{$t}{Name};
    }

    #And finally create the actual rule
    $schema->resultset('Fwrule')->create( {
      number      => $rule_num,
      name        => $rule->{name},
      description => $rule->{comments},
      enabled     => $rule->{disabled} ne 'true',
      action      => $action,
      srcnot      => $rule->{src}{op} eq 'not in',
      sourceset   => $src_id,
      dstnot      => $rule->{dst}{op} eq 'not in',
      destination => $dst_id,
      track       => $track,
      service     => $svc_id,
      source      => $source,
      });
  }
  
  for my $n (sort keys %{$d{'rule-base'}}) {
    next unless $n =~ /^_nat (\d+)/;

    my $nat_num = $1 + 0;

    my $nat = $d{'rule-base'}{$n};
    my $nattype = $nat->{src_adtr_translated}{adtr_method};
    $nattype =~ s/adtr_method_//;

    my $orig_src_id = $schema->resultset('Objectset')->create( {
      name => "orig_src: $nat_num", source => $source })->id;
    my $orig_dst_id = $schema->resultset('Objectset')->create( {
      name => "orig_dst: $nat_num", source => $source })->id;
    my $orig_svc_id = $schema->resultset('Objectset')->create( {
      name => "orig_svc: $nat_num", source => $source })->id;

    my $nat_src_id = $schema->resultset('Objectset')->create( {
      name => "nat_src: $nat_num", source => $source })->id;
    my $nat_dst_id = $schema->resultset('Objectset')->create( {
      name => "nat_dst: $nat_num", source => $source })->id;
    my $nat_svc_id = $schema->resultset('Objectset')->create( {
      name => "nat_svc: $nat_num", source => $source })->id;

    for my $o (grep /^_ref /, keys %{$nat->{src_adtr}}) {
      my $uid = $nat->{src_adtr}{$o}{Uid};
      my $type = $d{_uid}{$uid}{type};
      $schema->resultset('Objectsetlist')->create( {
        objectset => $orig_src_id,
	type      => $type,
	$type     => $d{_uid}{$uid}{id},
      });
    }

    for my $o (grep /^_ref /, keys %{$nat->{dst_adtr}}) {
      my $uid = $nat->{dst_adtr}{$o}{Uid};
      my $type = $d{_uid}{$uid}{type};
      $schema->resultset('Objectsetlist')->create( {
        objectset => $orig_dst_id,
	type      => $type,
	$type     => $d{_uid}{$uid}{id},
      });
    }

    for my $o (grep /^_ref /, keys %{$nat->{services_adtr}}) {
      my $uid = $nat->{services_adtr}{$o}{Uid};
      my $type = $d{_uid}{$uid}{type};
      $schema->resultset('Objectsetlist')->create( {
        objectset => $orig_svc_id,
	type      => $type,
	$type     => $d{_uid}{$uid}{id},
      });
    }

    for my $o (grep /^_ref /, keys %{$nat->{src_adtr_translated}}) {
      my $uid = $nat->{src_adtr_translated}{$o}{Uid};
      my $type = $d{_uid}{$uid}{type};
      $schema->resultset('Objectsetlist')->create( {
        objectset => $nat_src_id,
	type      => $type,
	$type     => $d{_uid}{$uid}{id},
      });
    }

    for my $o (grep /^_ref /, keys %{$nat->{dst_adtr_translated}}) {
      my $uid = $nat->{dst_adtr_translated}{$o}{Uid};
      my $type = $d{_uid}{$uid}{type};
      $schema->resultset('Objectsetlist')->create( {
        objectset => $nat_dst_id,
	type      => $type,
	$type     => $d{_uid}{$uid}{id},
      });
    }

    for my $o (grep /^_ref /, keys %{$nat->{services_adtr_translated}}) {
      my $uid = $nat->{services_adtr_translated}{$o}{Uid};
      my $type = $d{_uid}{$uid}{type};
      $schema->resultset('Objectsetlist')->create( {
        objectset => $nat_svc_id,
	type      => $type,
	$type     => $d{_uid}{$uid}{id},
      });
    }

    #And finally create the actual nat
    $schema->resultset('Natrule')->create( {
      number      => $nat_num,
      name        => $nat->{name},
      description => $nat->{comments},
      enabled     => $nat->{disabled} ne 'true',
      nattype     => $nattype,
      origsrcset  => $orig_src_id,
      origdstset  => $orig_dst_id,
      origsvcset  => $orig_svc_id,
      natsrcset   => $nat_src_id,
      natdstset   => $nat_dst_id,
      natsvcset   => $nat_svc_id,
      source      => $source,
      });
  }

}

1;
