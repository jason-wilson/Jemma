package Jemma::Import::F5;
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

sub getline
{
  my $fh = shift;
  my ($line) = $fh->getline;
  return undef unless defined $line;
  $line =~ s/[\n\r]+$//;
  return $line;
}

sub get_block
{
  my $fh = shift;
  my $line = getline($fh);
  my %ret;

  return unless defined $line;

  if ($line =~ /^(\S+) (\S+) (\S+) {(.*)/ ) {
    my ($section, $type, $name) = ($1, $2, $3);
    my $rest = $4;
    if ($rest =~ /}$/) { # One liner
      print "One-line: $section -> $type -> $name\n";
      $ret{$section}{$type}{$name} = "";
      return \%ret;
    }

    # Otherwise multi-line
    print "Multi-line: $section -> $type -> $name\n";
    $line = getline($fh);

    while (defined $line and $line !~ /^}/ ) {

      if ($line =~ /^    (\S+) { (.*) }/ ) {
	$ret{$section}{$type}{$name}{$1} = $2;
	$line = getline($fh);
	next;
      } elsif ($line =~ /^    (\S+) ([\w\/"].*)/ ) {
	$ret{$section}{$type}{$name}{$1} = $2;
	$line = getline($fh);
	next;
      } elsif ($line =~ /^    (\S+) {$/) {
        # Got a sub-list, remember name
	my $list = $1;
        $line = getline($fh);
	if ($line =~ /^\s+{$/) {
	  # Got an array of items, start counter
	  my $cnt = 0;
	  $line = getline($fh);
	  while (defined $line and $line !~ /^    }$/) {
	    if ($line =~ /^ {8}}$/) {
	      $cnt++;
	      $line = getline($fh);
	      if ($line =~ /^ {8}{$/) {
		$line = getline($fh);
	      }
	      next;
	    }
	    if ($line =~ /\s+(\S+) "(\S+)"/) {
	      $ret{$section}{$type}{$name}{$list}{$cnt}{$1} = $2;
	      $line = getline($fh);
	      next;
	    }
	    if ($line =~ /\s+(\S+) (\S+)/) {
	      $ret{$section}{$type}{$name}{$list}{$cnt}{$1} = $2;
	      $line = getline($fh);
	      next;
	    }
	    $line = getline($fh);
	  }
	}
      }
      $line = getline($fh);
    }
  }
  return \%ret;
}

sub importdata {
  my ($self) = shift;
  my ($file) = shift;

  my $name;

  open my $fh, '<', $file;
  while (my ($get) = get_block($fh)) {
    print "Got block: $get\n";
    print Dumper($get);
  }
}

1;
__DATA__
  my $line = getline($fh);
  while (defined $line) {

    if ($line =~ /^cm device (\S+) {/ ) {
      print "$1\n";
      $line = getline($fh);

      while (defined $line and $line !~ /^}/ ) {

	if ($line =~ /^    (\S+) { (.*) }/ ) {
	  printf "  %-20s %s\n", $1, $2;
	  $line = getline($fh);
	  next;
	} elsif ($line =~ /^    (\S+) ([\w\/"].*)/ ) {
	  printf "  %-20s %s\n", $1, $2;
	  $line = getline($fh);
	  next;
	} else {
	  #print "TODO: $line\n";
	}
	$line = getline($fh);
	#print "NOW: $line\n";
      }
    }

    $line = getline($fh);
  }
}

1;

__DATA__
To find:
  NTP
  DNS
  Local users
  VS, Pools, nodes
  Certificates
    Expiry date
  APM things:
    AAA servers
    Webtops
    ACL's
  ASM things:
    Policies
    Active/Transparent
