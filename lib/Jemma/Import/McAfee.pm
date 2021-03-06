
package Jemma::Import::McAfee;
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

  $schema->resultset('Source')->search( { name => $source } )->delete_all;
  $source = $schema->resultset('Source')->find_or_create( { name => $source })->id;

  # Create special objectsets first - will be used in multiple policy rules
  my $any = $schema->resultset('Objectset')->create( {
    name => "any", source => $source })->id;
  my $fwrule_number = 1;

  my %data;

  for my $file (@_) {
    open my $fh, $file or die "Can't open ", $file, ": $!";

    while (<$fh>) {
      s/[\n\r]+//;

      # Process all lines that start with the object type and the word 'add'
      if (/^(\w+) add (.*)/ or /^(application) modify (.*)/ ) {
	my ($type) = $1;
	my ($data) = $2;


	# Will assume that first key=value pair uniquely defines this object
	# NOTE: policy is of form: policy add table=TYPE name='BLAH'
	#   Re-arrnage with some regex..
	if ($type eq 'policy' and $data =~ /^(table=\w+) (.*)/) {
	  $data = "$2 $1";
	}
	my ($first_k, $first_v);

	# Loop until line is fully processed
	while ($data ne '') {

	  # Look for a key='value with spaces'
	  if ($data =~ /^(\w+)='([^']+)'/ ) {
	    $data =~ s/^\w+='[^']+'\s*//;

	  # Look for a key=value_no_spaces
	  } elsif ($data =~ /^(\w+)=(\S+)/ ) {
	    $data =~ s/^\w+=\S+\s*//;

	  # Any other options? If so die for now
	  } else {
	    die "  Got $data left - can't process\n";
	  }

	  # Haven't got the first key yet, so store it
	  if (! defined $first_k) {
	    $first_k = $1;
	    $first_v = $2;
	  } else {
	    # Store others into hash
	    $data{$type}{$first_v}{$1} = $2;
	    #print "$type $first_v has $1=$2\n";
	  }
	}

	# Got whole line, now add to relevant table
	if ($type eq 'ipaddr' or $type eq 'subnet' or $type eq 'iprange' or $type eq 'host') {
	  my ($start, $end);
	  if ($type eq 'ipaddr' or $type eq 'host') {

	    # Ignore localhost entry
	    next if $first_v eq 'localhost';

	    $start = Jemma::Utils::ip_to_number($data{$type}{$first_v}{ipaddr});
	    $start //= Jemma::Utils::ip_to_number($data{$type}{$first_v}{ipaddrs});
	    $end = $start;
	  } elsif ($type eq 'subnet') {
	    my $cidr = $data{$type}{$first_v}{subnet} . "/" .
		       $data{$type}{$first_v}{bits};

	    ($start, $end) = Jemma::Utils::cidr_to_range($cidr);
	  } elsif ($type eq 'iprange') {
	    $start = Jemma::Utils::ip_to_number($data{$type}{$first_v}{begin});
	    $end = Jemma::Utils::ip_to_number($data{$type}{$first_v}{end});
	  }

	  my $id = $schema->resultset('Ip')->create( {
	    start       => $start,
	    end         => $end,
	    name        => $first_v,
	    description => $data{$type}{$first_v}{description},
	    source      => $source,
	    });
	  $data{$type}{$first_v}{_id} = $id->id;

	  # Add extra details
	  for my $k (keys %{$data{$type}{$first_v}}) {
	    next if $k =~ /^_/; # Skip our internal things
	    $schema->resultset('Ipextra')->create( {
	      ip    => $id->id,
	      key   => $k,
	      value => $data{$type}{$first_v}{$k},
	      });
	  }

	} elsif ($type eq 'netgroup') {
	  # This is a group, just add group for now - add members later
	  my $id = $schema->resultset('Grp')->create( {
	    name        => $first_v,
	    description => $data{$type}{$first_v}{description},
	    source      => $source,
	  });
	  $data{$type}{$first_v}{_id} = $id->id;

	} elsif ($type eq 'application') {
	  my $protocol = 'unknown';
	  my ($ports);
	  if ($data{$type}{$first_v}{tcp_ports} =~ /\d/) {
	    $protocol = 'tcp';
	    $ports = $data{$type}{$first_v}{tcp_ports};
	  } elsif ($data{$type}{$first_v}{udp_ports} =~ /\d/) {
	    $protocol = 'udp';
	    $ports = $data{$type}{$first_v}{udp_ports};
	  }

	  my $id = $schema->resultset('Service')->create( {
	    name        => $first_v,
	    description => $data{$type}{$first_v}{description},
	    protocol    => $protocol,
	    ports       => $ports,
	    source      => $source,
	  });
	  $data{$type}{$first_v}{_id} = $id->id;

	} elsif ($type eq 'appgroup') {
	  my $members = $data{$type}{$first_v}{members};

	  print "Doing $first_v\n";
	  my $svcgrp = $schema->resultset('Servicegrp')->create( {
	    name        => $first_v,
	    description => $data{$type}{$first_v}{description},
	    source      => $source,
	  })->id;
	  $data{appgroup}{$first_v}{_id} = $svcgrp;

	  for my $object (split /,/, $members) {
	    my ($obj_type, $obj_name) = split /:/, $object;
	    $obj_type = 'application' if $obj_type eq 'custom';

	    if (! exists $data{$obj_type}{$obj_name}) {
	      my $protocol = 'unknown';
	      $protocol = 'icmp' if $obj_name eq 'ICMP';

	      my $id = $schema->resultset('Service')->create( {
		name        => $obj_name,
		description => 'Auto-created',
		protocol    => $protocol,
		source      => $source,
	      });
	      $data{$obj_type}{$obj_name}{_id} = $id->id;
	      print "  Have added $obj_type of $obj_name\n";
	    }

	    $schema->resultset('Servicegrpgrp')->create( {
	      servicegrp => $svcgrp,
	      service    => $data{$obj_type}{$obj_name}{_id},
	    });

	  }

	} elsif ($type eq 'policy') {
	  if ($data{$type}{$first_v}{table} eq 'rule') {
	    my $pos = $data{$type}{$first_v}{pos};
	    #print "$pos: $first_v\n";

	    my $src_id = $schema->resultset('Objectset')->create( {
	      name => "src: $first_v", source => $source })->id;
	    my $dst_id = $schema->resultset('Objectset')->create( {
	      name => "dst: $first_v", source => $source })->id;
	    my $svc_id = $schema->resultset('Objectset')->create( {
	      name => "svc: $first_v", source => $source })->id;

	    for my $src (split /,/, $data{$type}{$first_v}{source}) {
	      #print "  src: $src\n";

	      my ($obj_type, $obj_name) = split /:/, $src;
	      my $db_type = 'ip' if ($obj_type eq 'ipaddr' or $obj_type eq 'subnet' or $obj_type eq 'iprange' or $obj_type eq 'host');
	      $db_type = 'grp' if $obj_type eq 'netgroup';
	      $db_type = 'any' if $obj_type eq 'all' or $obj_type eq '*';

	      my (@link) = ($db_type, $data{$obj_type}{$obj_name}{_id}) if $db_type ne 'any';
	      $schema->resultset('Objectsetlist')->create( {
		objectset => $src_id,
		type      => $db_type,
		@link,
	      });

	    }

	    for my $dst (split /,/, $data{$type}{$first_v}{dest}) {
	      #print "  dst: $dst\n";

	      my ($obj_type, $obj_name) = split /:/, $dst;
	      my $db_type = 'ip' if ($obj_type eq 'ipaddr' or $obj_type eq 'subnet' or $obj_type eq 'iprange' or $obj_type eq 'host');
	      $db_type = 'grp' if $obj_type eq 'netgroup';
	      $db_type = 'any' if $obj_type eq 'all' or $obj_type eq '*';

	      my (@link) = ($db_type, $data{$obj_type}{$obj_name}{_id}) if $db_type ne 'any';
	      $schema->resultset('Objectsetlist')->create( {
		objectset => $dst_id,
		type      => $db_type,
		@link,
	      });

	    }

	    for my $svc (split /,/, $data{$type}{$first_v}{application}) {

	      my ($obj_type, $obj_name) = split /:/, $svc;
	      $obj_type = 'application' if $obj_type eq 'custom';
	      my $db_type = 'service' if $obj_type eq 'application';
	      $db_type = 'servicegrp' if $obj_type eq 'appgroup';
	      die "Don't know what type $obj_type is\n" unless defined $db_type;


	      if (! exists $data{$obj_type}{$obj_name}) {
		my $protocol = 'unknown';
		$protocol = 'icmp' if $obj_name eq 'ICMP';

		my $id = $schema->resultset('Service')->create( {
		  name        => $obj_name,
		  description => 'Auto-created',
		  protocol    => $protocol,
		  source      => $source,
		});
		$data{$obj_type}{$obj_name}{_id} = $id->id;
		print "  Have added $obj_type of $obj_name\n";
	      }

	      $schema->resultset('Objectsetlist')->create( {
		objectset => $svc_id,
		type      => $db_type,
		$db_type  => $data{$obj_type}{$obj_name}{_id},
	      });

	    }

	    $schema->resultset('Fwrule')->create( {
	      number      => $fwrule_number++,
	      name        => $first_v,
	      action      => $data{$type}{$first_v}{action},
	      sourceset   => $src_id,
	      destination => $dst_id,
	      service     => $svc_id,
	      source      => $source,
	      description => $data{$type}{$first_v}{description},
	    });


	  } else {
	    print "----- Got a $first_v: ", $data{$type}{$first_v}{table}, "\n";
	  }
	} else {
	  warn "Not loading type of $type: $first_v\n";
	}
      }
    }
  }

  # Now to add group members
  for my $group (keys %{$data{netgroup}}) {
    my ($members) = $data{netgroup}{$group}{members};
    for my $type_member(split /,/, $members) {
      my ($type, $member) = split /:/, $type_member;

      if ($type eq 'ipaddr' or $type eq 'subnet' or $type eq 'iprange' or $type eq 'host') {
        $schema->resultset('Ipgrp')->create( {
	  ip  => $data{$type}{$member}{_id},
	  grp => $data{netgroup}{$group}{_id},
	});
      } elsif ($type eq 'netgroup') {
        $schema->resultset('Grpgrp')->create( {
	  parent => $data{netgroup}{$group}{_id},
	  child  => $data{netgroup}{$member}{_id},
	});
      } else {
        warn "Don't know how to add type of $type ($member) to a group..\n";
      }
    }
  }
}

1;
 
