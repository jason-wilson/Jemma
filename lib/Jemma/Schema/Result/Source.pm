use utf8;
package Jemma::Schema::Result::Source;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Source

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<source>

=cut

__PACKAGE__->table("source");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 grps

Type: has_many

Related object: L<Jemma::Schema::Result::Grp>

=cut

__PACKAGE__->has_many(
  "grps",
  "Jemma::Schema::Result::Grp",
  { "foreign.source" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ipaddrs

Type: has_many

Related object: L<Jemma::Schema::Result::Ipaddr>

=cut

__PACKAGE__->has_many(
  "ipaddrs",
  "Jemma::Schema::Result::Ipaddr",
  { "foreign.source" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ips

Type: has_many

Related object: L<Jemma::Schema::Result::Ip>

=cut

__PACKAGE__->has_many(
  "ips",
  "Jemma::Schema::Result::Ip",
  { "foreign.source" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-29 15:58:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RTAeFN5L/9xbST2Qk7IxyQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
