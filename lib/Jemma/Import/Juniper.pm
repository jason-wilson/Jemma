package Jemma::Import::Juniper;
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

  my %db;
  my $num;
  my $rule_num = 1;

  $db{group}{Any}{id} = $schema->resultset('Grp')->create( {
    name => "Any",
    source => $source })->id;

  $db{service}{ANY}{id} = $schema->resultset('Service')->create( {
    name => "ANY",
    protocol => 'Any',
    source => $source })->id;

  open my $fh, '<', $file;
  while (<$fh>) {
    s/[\n\r]+$//;

    if (/^set service ".*" /) {
      if (
      	  /^set service "(.*)" protocol (\w+) src-port .* dst-port (.*)/ or
      	  /^set service "(.*)" \+ (\w+) src-port .* dst-port (.*)/
	) {
	my ($name, $proto, $ports) = ($1, $2, $3);

	my ($a, $b) = split /-/, $ports;
	$ports = $a if $a == $b;

	$db{service}{$name}{proto} = $proto;
	$db{service}{$name}{ports}{$ports}++;
	next;
      }
      warn "Unknown service: $_\n";
    }

    if (/^set address "(.*)"/) {
      if (/^set address "(.*)" "(.*)" ([\d\.]+) ([\d\.]+)/) {
	my ($zone, $name, $ip, $mask) = ($1, $2, $3, $4);

	my ($cidr) = Net::CIDR::addrandmask2cidr($ip, $mask);
	my ($start, $end) = Jemma::Utils::cidr_to_range($cidr);

	my $id = $schema->resultset('Ip')->create( {
	  start       => $start,
	  end         => $end,
	  name        => $name,
	  description => "$name in zone $zone",
	  source      => $source,
	});
	$db{ip}{$name}{id} = $id;
	next;
      }

      if (/^set address "(.*)" "(.*)" (\S+)/) {
	my $id = $schema->resultset('Grp')->create( {
	  name        => $2,
	  description => "$2 as $3",
	  source      => $source,
	})->id;
	$db{group}{$2}{id} = $id;
	next;
      }

      warn "Unknown address $_\n";
    }

    if (/^set group address "([^"]*)" "([^"]*)"$/) {
      my $id = $schema->resultset('Grp')->create( {
        name        => $2,
	description => "$2 in zone $1",
	source      => $source,
      });
      $db{group}{$2}{id} = $id;
    }

    if (/^set group address "([^"]*)" "([^"]*)" add "(.*)"$/) {
      if (defined $db{ip}{$3}{id}) {
	$schema->resultset('Ipgrp')->create( {
	  ip  => $db{ip}{$3}{id},
	  grp => $db{group}{$2}{id},
	});
      } elsif (defined $db{group}{$3}{id}) {
	$schema->resultset('Grpgrp')->create( {
	  parent => $db{group}{$2}{id},
	  child  => $db{group}{$3}{id},
	});
      } else {
        warn "Cant add $3 to group $2 as I cant find it\n";
      }
    }

    if (/^set policy id (\d+) name "([^"]*)" from "([^"]*)" to "([^"]*)"  "([^"]*)" "([^"]*)" "([^"]*)" (.+)/) {
      $num = $1;
      my ($name, $szone, $dzone, $src, $dst, $service, $action) = ($2, $3, $4, $5, $6, $7, $8);
      $db{rule}{$rule_num}{name} = $name;
      $db{rule}{$rule_num}{description} = "$szone to $dzone";
      $db{rule}{$rule_num}{src}{$src}++;
      $db{rule}{$rule_num}{dst}{$dst}++;
      $db{rule}{$rule_num}{service}{$service}++;
      $db{rule}{$rule_num}{action} = $action;
      next;
    }

    if (/^set policy id (\d+) from "([^"]*)" to "([^"]*)"  "([^"]*)" "([^"]*)" "([^"]*)" (.+)/) {
      $num = $1;
      my ($szone, $dzone, $src, $dst, $service, $action) = ($2, $3, $4, $5, $6, $7);
      $db{rule}{$rule_num}{name} = "Rule id $num";
      $db{rule}{$rule_num}{description} = "$szone to $dzone";
      $db{rule}{$rule_num}{src}{$src}++;
      $db{rule}{$rule_num}{dst}{$dst}++;
      $db{rule}{$rule_num}{service}{$service}++;
      $db{rule}{$rule_num}{action} = $action;
      next;
    }
    next if /^set policy id (\d+)$/;

    if (defined $num) {
      $num = undef, $rule_num++, next if /^exit/;
        
      $db{rule}{$rule_num}{disable}++,     next if /^set policy id (\d+) disable$/;
      $db{rule}{$rule_num}{src}{$1}++,     next if /^set src-address "([^"]*)"/;
      $db{rule}{$rule_num}{dst}{$1}++,     next if /^set dst-address "([^"]*)"/;
      $db{rule}{$rule_num}{service}{$1}++, next if /^set service "([^"]*)"/;
      warn "Try: $_\n";
    }

    if (/^set route ([\d\.\/]+) interface (\w+) gateway ([\d\.]+)/) {
      my ($ip, $intf, $gw) = ($1, $2, $3);
      print "Add $ip through $intf to $gw\n";

      my ($start, $end) = Jemma::Utils::cidr_to_range($ip);
      $gw = Jemma::Utils::ip_to_number($gw);

      my $id = $schema->resultset('Route')->create( {
	start       => $start,
	end         => $end,
	interface   => $intf,
	gateway     => $gw,
	metric      => 0,
	source      => $source,
      });
    }

  }

  for (keys %{$db{service}}) {
    next if defined $db{service}{$_}{id};
    my $id = $schema->resultset('Service')->create( {
      name        => $_,
      description => $_,
      protocol    => $db{service}{$_}{proto},
      ports       => join (',', sort keys %{$db{service}{$_}{ports}}),
      source      => $source,
      });
    $db{service}{$_}{id} = $id;
  }

  for my $r (keys %{$db{rule}}) {

    my $src_id = $schema->resultset('Objectset')->create( {
      name => "src: $r", source => $source })->id;
    my $dst_id = $schema->resultset('Objectset')->create( {
      name => "dst: $r", source => $source })->id;
    my $svc_id = $schema->resultset('Objectset')->create( {
      name => "svc: $r", source => $source })->id;

    for (keys %{$db{rule}{$r}{src}} ) {
      my ($type, $id);

      if (defined $db{ip}{$_}{id}) {
        $type = 'ip';
	$id = $db{ip}{$_}{id};
      }
      if (defined $db{group}{$_}{id}) {
        $type = 'grp';
	$id = $db{group}{$_}{id};
      }

      die "Unknown type in rule $r for name '$_'\n" unless defined $type;

      $schema->resultset('Objectsetlist')->create( {
        objectset => $src_id,
	type	  => $type,
	$type     => $id,
      } );
    }

    for (keys %{$db{rule}{$r}{dst}} ) {
      my ($type, $id);

      if (/^VIP\((.*)\)/) {
	my $ip = $1;
	my $start = Jemma::Utils::ip_to_number($ip);
	my $id = $schema->resultset('Ip')->create( {
	  start       => $start,
	  end         => $start,
	  name        => $_,
	  description => "VIP $ip",
	  source      => $source,
	});
	$db{ip}{$_}{id} = $id;
      }

      if (defined $db{ip}{$_}{id}) {
        $type = 'ip';
	$id = $db{ip}{$_}{id};
      }
      if (defined $db{group}{$_}{id}) {
        $type = 'grp';
	$id = $db{group}{$_}{id};
      }

      die "Unknown type in rule $r for name '$_'\n" unless defined $type;
      $schema->resultset('Objectsetlist')->create( {
        objectset => $dst_id,
	type	  => $type,
	$type     => $id,
      } );
    }

    for (keys %{$db{rule}{$r}{service}} ) {
      my $type = 'service';
      my $id = $db{service}{$_}{id};

      if (! defined $id) {
	$db{service}{$_}{id} = $schema->resultset('Service')->create( {
	  name => $_,
	  protocol => 'tcp',
	  source => $source })->id;
	$id = $db{service}{$_}{id};
      }

      $schema->resultset('Objectsetlist')->create( {
        objectset => $svc_id,
	type	  => $type,
	$type     => $id,
      } );
    }

    $schema->resultset('Fwrule')->create( {
      number      => $r,
      name        => $db{rule}{$r}{name},
      action      => $db{rule}{$r}{action},
      description => $db{rule}{$r}{description},
      enabled     => ! defined $db{rule}{$r}{disable},
      sourceset   => $src_id,
      destination => $dst_id,
      service     => $svc_id,
      source      => $source,
    });
  }

}

1;
