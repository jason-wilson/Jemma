use utf8;
package Jemma::Schema::Result::Ipgrp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Ipgrp

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ipgrp>

=cut

__PACKAGE__->table("ipgrp");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 ip

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 grp

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ip",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "grp",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 grp

Type: belongs_to

Related object: L<Jemma::Schema::Result::Grp>

=cut

__PACKAGE__->belongs_to(
  "grp",
  "Jemma::Schema::Result::Grp",
  { id => "grp" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 ip

Type: belongs_to

Related object: L<Jemma::Schema::Result::Ip>

=cut

__PACKAGE__->belongs_to(
  "ip",
  "Jemma::Schema::Result::Ip",
  { id => "ip" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-29 15:27:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GsSTrvBVw9a7HHRmzQhHFw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
