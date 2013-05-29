
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

      my ($list_type, $list_key);
      if ($type eq 'ipaddr') {
	$list_type = $type;
	$list_key = $self->{data}{ipaddr}{name}{$first_v}{ipaddr};
      } elsif ($type eq 'subnet') {
	$list_type = $type;
	$list_key = $self->{data}{subnet}{name}{$first_v}{subnet} .
	           "/" .
		   $self->{data}{subnet}{name}{$first_v}{bits};
      } elsif ($type eq 'iprange') {
	$list_type = $type;
	$list_key = $self->{data}{iprange}{name}{$first_v}{begin} .
	           "-" .
		   $self->{data}{iprange}{name}{$first_v}{end};
      } elsif ($type eq 'netgroup') {
        $list_type = 'group';
	$list_key = $first_v;
      }

      if (defined $list_type) {
        $self->{$list_type}{$list_key} = $first_v;
      }

    }
  }
}

sub list {
  my ($self) = shift;
  my ($type) = shift;

  return keys %{$self->{$type}};
}
  
1;
 
