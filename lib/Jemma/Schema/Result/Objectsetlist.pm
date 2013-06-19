use utf8;
package Jemma::Schema::Result::Objectsetlist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Objectsetlist

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<objectsetlist>

=cut

__PACKAGE__->table("objectsetlist");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 objectset

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 type

  data_type: 'text'
  is_nullable: 0

=head2 ip

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 grp

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 service

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 servicegrp

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "objectset",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "type",
  { data_type => "text", is_nullable => 0 },
  "ip",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "grp",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "service",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "servicegrp",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 ip

Type: belongs_to

Related object: L<Jemma::Schema::Result::Ip>

=cut

__PACKAGE__->belongs_to(
  "ip",
  "Jemma::Schema::Result::Ip",
  { id => "ip" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 objectset

Type: belongs_to

Related object: L<Jemma::Schema::Result::Objectset>

=cut

__PACKAGE__->belongs_to(
  "objectset",
  "Jemma::Schema::Result::Objectset",
  { id => "objectset" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 service

Type: belongs_to

Related object: L<Jemma::Schema::Result::Service>

=cut

__PACKAGE__->belongs_to(
  "service",
  "Jemma::Schema::Result::Service",
  { id => "service" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 servicegrp

Type: belongs_to

Related object: L<Jemma::Schema::Result::Servicegrp>

=cut

__PACKAGE__->belongs_to(
  "servicegrp",
  "Jemma::Schema::Result::Servicegrp",
  { id => "servicegrp" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-06-19 15:17:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pK+Bw/NgVDrlo3YhO1mDMQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
