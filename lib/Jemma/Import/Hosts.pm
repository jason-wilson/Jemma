package Jemma::Import::Hosts;
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
  my ($file) = shift;

  $schema->resultset('Source')->search( { name => $source } )->delete_all;
  $source = $schema->resultset('Source')->find_or_create( { name => $source })->id;

  open my $fh, '<', $file;
  while (<$fh>) {
    s/[\n\r]+$//;
    s/#.*//;

    if (/^([\d\.]+)\s+(.*)/) {
      my $addr = $1;
      my $names = $2;

      for (split /\s+/, $names) {
	my $number = Jemma::Utils::ip_to_number($addr);
	$schema->resultset('Ip')->create( {
	  start       => $number,
	  end         => $number,
	  name        => $_,
	  description => 'From hosts file',
	  source      => $source,
	});
      }
    }
  }
}

1;

