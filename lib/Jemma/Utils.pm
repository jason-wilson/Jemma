
package Jemma::Utils;

use strict;
use Net::CIDR;

my %cache;

sub ip_to_number {
  my $ip = shift;
  return unless defined $ip;

  if (! defined $cache{$ip}) {
    if ( $ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)/ ) {
      $cache{$ip} = ($1 * 256 * 256 *256) + ($2 *256 *256) + ($3 * 256) + $4;
      $cache{ $cache{$ip} } = $ip;
    } else {
      return 0;
    }
  }

  return $cache{$ip};
}

sub number_to_ip {
  my $number = shift;
  my $tmp = $number;

  if (! defined $cache{$tmp}) {
    my $a = int($tmp / (256*256*256));
    $tmp -= $a * 256 * 256 *256;
    my $b = int($tmp / (256*256));
    $tmp -= $b * 256 *256;
    my $c = int($tmp / 256);
    $tmp -= $c * 256;

    my $ip = "$a.$b.$c.$tmp";

    $cache{$number} = $ip;
    $cache{ $ip } = $number;
  }

  return $cache{$number};
}

sub cidr_to_range {
  my $cidr = shift;

  my ($range) = Net::CIDR::cidr2range $cidr;
  my ($from, $to) = split /-/, $range;

  return (ip_to_number($from), ip_to_number($to));
}

sub range_to_cidr {
  my $from = shift;
  my $to = shift;

  return join ' ', Net::CIDR::range2cidr(
  	number_to_ip($from) . '-' .
  	number_to_ip($to),
      );
}

sub range_to_netmask {
  my $from = shift;
  my $to = shift;
  my (@cidr_to_netmask) = (
    '0.0.0.0',
    '128.0.0.0', '192.0.0.0', '224.0.0.0', '240.0.0.0',
    '248.0.0.0', '252.0.0.0', '254.0.0.0', '255.0.0.0',
    '255.128.0.0', '255.192.0.0', '255.224.0.0', '255.240.0.0',
    '255.248.0.0', '255.252.0.0', '255.254.0.0', '255.255.0.0',
    '255.255.128.0', '255.255.192.0', '255.255.224.0', '255.255.240.0',
    '255.255.248.0', '255.255.252.0', '255.255.254.0', '255.255.255.0',
    '255.255.255.128', '255.255.255.192', '255.255.255.224', '255.255.255.240',
    '255.255.255.248', '255.255.255.252', '255.255.255.254', '255.255.255.255',
  );

  my (@list) = Net::CIDR::range2cidr(
  	number_to_ip($from) . '-' .
  	number_to_ip($to),
      );
  return 'undefined' if $#list > 0;
  my $ret = shift @list;
  $ret =~ s:.*/::;
  return $cidr_to_netmask[$ret];
}

sub commify {
  local $_  = shift;
  1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
  return $_;
}

1;
