package Jemma::Import::Nmap;
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
  my ($net) = shift;

  open my $fh, '-|', 'nmap -oX - -sP ' . $net;

  my $parser = XML::LibXML->new();
  my $doc = $parser->parse_fh($fh);

  for my $host ($doc->findnodes('/nmaprun/host')) {
    my ($address) = $host->findnodes('./address');
    my $ip = $address->getAttribute('addr');

    my ($hostname) = $host->findnodes('./hostnames/hostname');
    my $name = defined $hostname ? $hostname->getAttribute('name') : $ip;

    print "$ip is $name\n";
    $self->{data}{$ip} = $name;
  }
}

1;

