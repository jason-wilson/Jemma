package Jemma::Import::QPSIPDB;
use Jemma::Utils;
use strict;
use Spreadsheet::ParseExcel;

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

  my $fmt = "  %-18s %s %s\n";

  my $book = new Spreadsheet::ParseExcel::Workbook->Parse($file);
  foreach my $sheet (@{$book->{Worksheet}}) {
    next if $sheet->{Name} eq 'Lookup';

    print "Working on sheet " . $sheet->{Name} . "\n";
    if ($sheet->{Name} eq 'Summary') {
      for (my $row = 1 ; defined $sheet->{MaxRow} && $row <= $sheet->{MaxRow}; $row++) {
	my $name = $sheet->{Cells}[$row][6]->Value;
	next if !defined $name;
	my $ip = $sheet->{Cells}[$row][0]->Value;
	my $mask = $sheet->{Cells}[$row][5]->Value;
	printf $fmt, "$ip/$mask", $name, $sheet->{Name};

	my ($start, $end) = Jemma::Utils::cidr_to_range($ip . "/" . $mask);
	my $id = $schema->resultset('Ip')->create( {
	  start       => $start,
	  end         => $end,
	  name        => $name,
	  description => "From IPDB file",
	  source      => $source,
	});
      }
      next;
    }

    my $size;
    $size //= $sheet->{Cells}[1][3];

    die "Can't find size\n" unless defined $size;
    $size = $size->Value;

    for (my $row = 4 ; defined $sheet->{MaxRow} && $row <= $sheet->{MaxRow}; $row++) {
      my $name = $sheet->{Cells}[$row][1];
      $name = $sheet->{Cells}[$row][2] if ! defined $name or $name->Value !~ /./;
      next if !defined $name;
      $name = $name->Value;

      my $ip = $sheet->{Cells}[$row][0];
      next unless defined $ip;
      $ip = $ip->Value;
      next if $ip !~ /^[0-9\.]+$/ or $ip =~ / - /;

      my $cidr;
      if ($name eq 'Network') {
        $name = $sheet->{Cells}[1][0]->Value;
	$cidr = "$ip/$size";
      } else {
        $cidr = "$ip/32";
      }

      my $comment = $sheet->{Cells}[$row][3];
      $comment = defined $comment ? $comment->Value : "On sheet " . $sheet->{Name};

      printf $fmt, $cidr, $name, $comment;
      my ($start, $end) = Jemma::Utils::cidr_to_range($cidr);
      my $id = $schema->resultset('Ip')->create( {
	start       => $start,
	end         => $end,
	name        => $name,
	description => $comment,
	source      => $source,
      });
    }
  }
}

1;

__DATA__
        
  my @d;
  $d[0] = 'ckp';
  my %data;

  # Remember ReferenceObject count
  my $refobj = 0;

  open my $fh, '<', $file;
  while (<$fh>) {
    s/[\n\r]+$//;

    # Count how many tabs at start of line
    my ($idx) = s/\t//g;
    next unless $idx > 0;

    # Make sure array is only as big as current size
    @d = @d[0 .. $idx];

    if ( /:(\S+) \((.*)\)/ ) {
      $d[$idx] = $1;
      my $val = $2;
      if ($d[1] eq 'network_objects') {
	my (@key) = @d[2 .. $#d];
	my $host = shift @key;
	if ($#key >= 0 and $val =~ /./) {
	  #print join('|', @d), "=$val\n";
	  #print "$host: key is ", join('-', @key), " and value is ", $val, "\n";
	  my $key = join '-', @key;

	  # This is actually a list, so special case it
	  if ($key =~ /^ReferenceObject-(\w+)/) {
	    $data{$host}{ReferenceObject}{$refobj}{$1} = $val;
	    $refobj++ if $key eq 'ReferenceObject-Uid';

	  } else {
	    $refobj = 0;
	    $data{$host}{$key} = $val;
	  }

	}
      }
      next;
    }

    if ( /: \((.*)/ ) {
      $d[$idx] = $1;
      next;
    }

    if ( /:(\S+) \((.*)/ ) {
      $d[$idx] = $1;
      $d[$idx+1] = $2;
      next;
    }

  }
  close $fh;

  # Load hosts and subnet's first
  for my $host (sort keys %data) {
    if (exists $data{$host}{ipaddr} ) {
      if (exists $data{$host}{netmask}) {
	my $cidr = Net::CIDR::addrandmask2cidr(
	  $data{$host}{ipaddr},
	  $data{$host}{netmask},
	);

	my ($start, $end) = Jemma::Utils::cidr_to_range($cidr);

	my $id = $schema->resultset('Ip')->create( {
	  start       => $start,
	  end         => $end,
	  name        => $host,
	  description => $data{$host}{comments},
	  source      => $source,
	});
	$data{$host}{_id} = $id->id;
      } else {
	my $number = Jemma::Utils::ip_to_number($data{$host}{ipaddr});
	my $id = $schema->resultset('Ip')->create( {
	  start       => $number,
	  end         => $number,
	  name        => $host,
	  description => $data{$host}{comments},
	  source      => $source,
	});
	$data{$host}{_id} = $id->id;
      }
    } elsif (exists $data{$host}{ipaddr_first}) {
      my ($start) = Jemma::Utils::ip_to_number($data{$host}{ipaddr_first});
      my ($end)   = Jemma::Utils::ip_to_number($data{$host}{ipaddr_last});

      my $id = $schema->resultset('Ip')->create( {
	start       => $start,
	end         => $end,
	name        => $host,
	description => $data{$host}{comments},
	source      => $source,
      });
      $data{$host}{_id} = $id->id;
    }
  }

  # Load groups
  for my $group (sort keys %data) {
    if (exists $data{$group}{type} and $data{$group}{type} eq 'group') {
      my ($gid) = $schema->resultset('Grp')->create( {
        name        => $group,
	description => $data{$group}{comments},
	source      => $source,
      });
      $data{$group}{_id} = $gid->id;
    }
  }

  # Now load members of groups
  for my $group (sort keys %data) {
    if (exists $data{$group}{type} and $data{$group}{type} eq 'group') {
      for my $i (sort { $a <=> $b } keys %{$data{$group}{ReferenceObject}}) {
	my $name = $data{$group}{ReferenceObject}{$i}{Name};
	my $id = $data{$group}{_id};

	if ($data{$name}{type} eq 'group') {
	  # Sub-group
	  $schema->resultset('Grpgrp')->create( {
	    parent => $id,
	    child  => $data{$name}{_id},
	  });
	} else {
	  $schema->resultset('Ipgrp')->create( {
	    ip  => $data{$name}{_id},
	    grp => $id,
	  });
	}
      }
    }
  }

}

1;
