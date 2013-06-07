
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

  $source = $schema->resultset('Source')->find_or_create( { name => $source })->id;

  my %data;

  for my $file (@_) {
    open my $fh, $file or die "Can't open ", $file, ": $!";

    while (<$fh>) {
      s/[\n\r]+//;

      # Process all lines that start with the object type and the word 'add'
      if (/^(\w+) add (.*)/ ) {
	my ($type) = $1;
	my ($data) = $2;

	# Will assume that first key=value pair uniquely defines this object
	# within this type - need to confirm this is right
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
	    print "$type $first_v has $1=$2\n";
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
 
