
package Jemma::Import::McAfee;
use Jemma::Utils;
use strict;

use Data::Dumper;

sub new {
  my ($class) = shift;
  $class = ref($class) if ref($class);

  my $self = { @_ };

  bless $self, $class;
}

sub dump {
  my ($self) = shift;

  print Data::Dumper->Dump( [ $self->{ip} ]);
}

sub importdata {
  my ($self) = shift;
  my (%args) = @_;

  for my $k (keys %args) {
    $self->{$k} = $args{$k};
  }

  open my $fh, $self->{file} or die "Can't open ", $self->{file}, ": $!";
  while (<$fh>) {
    s/[\n\r]+//;

    # All lines start with the object type and the word 'add'
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
	  # Store into hash
	  $self->{data}{$type}{$first_k}{$first_v}{$1} = $2;
	}
      }

      if ($type eq 'ipaddr') {
        # This is an IP address - so remember for later
	$self->{ip}{ Jemma::Utils::ip_to_number($self->{data}{ipaddr}{name}{$first_v}{ipaddr}) } = $first_v;
      }

      if ($type eq 'subnet') {
        # This is an subnet address - so remember for later
	my $cidr = $self->{data}{subnet}{name}{$first_v}{subnet} .
	           "/" .
		   $self->{data}{subnet}{name}{$first_v}{bits};
	$self->{subnet}{ $cidr } = $first_v;
      }

      if ($type eq 'iprange') {
        # This is an range of address - so remember for later
	my $range = $self->{data}{iprange}{name}{$first_v}{begin} .
	           "-" .
		   $self->{data}{iprange}{name}{$first_v}{end};
	$self->{iprange}{ $range } = $first_v;
      }

    }
  }
}

sub iplist {
  my ($self) = shift;
  return sort { $a <=> $b } keys %{$self->{ip}};
}

sub subnetlist {
  my ($self) = shift;
  return keys %{$self->{subnet}};
}

sub rangelist {
  my ($self) = shift;
  return keys %{$self->{iprange}};
}

sub ip {
  my ($self) = shift;
  my ($ip) = shift;

  my $name = $self->{ip}{$ip};
  return $self->{data}{ipaddr}{name}{$name};
}

1;
 
