
package Jemma::Utils;

use strict;
use Net::CIDR;

my %cache;

sub ip_to_number {
  my $ip = shift;

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

1;
