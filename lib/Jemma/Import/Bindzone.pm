package Jemma::Import::Bindzone;
use Jemma::Utils;
use XML::LibXML;
use strict;

sub new {
  my ($class) = shift;
  $class = ref($class) if ref($class);

  my $self = { @_ };

  bless $self, $class;
}

sub importdata {
  my ($self) = shift;
  my ($file) = shift;

  my $name;

  open my $fh, '<', $file;
  while (<$fh>) {
    s/[\n\r]+//;
    if (/^([\w\.-]+)\s+IN\s+SOA\s/) {
      $name = $1;
      $name =~ s/\.in-addr\.arpa$//;
      next;
    }

    if (/^([\w\.@-]+)\s+IN\s+A\s+([\w\.:]+)/) {
      my $line = $1;
      my $addr = $2;

      $line = $name if $line eq '@'; 
      $line = $line . '.' . $name if $line !~ /\.$/;

      $self->{data}{$line}{ip} = $addr;
      $self->{data}{$line}{type} = 'A';
    }

    if (/^([\w\.@-]+)\s+IN\s+PTR\s+([\w\.:]+)/) {
      my $addr = $1;
      my $ptr = $2;

      $addr = $addr . '.' . $name if $addr !~ /\.$/;
      print "Got $addr\n";
      $addr = join '.', (split(/\./, $addr))[3,2,1,0];
      print "Got $addr\n";

      $self->{data}{$ptr}{ip} = $addr;
      $self->{data}{$ptr}{type} = 'PTR';
    }

  }
}

1;

