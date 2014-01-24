use utf8;
package Jemma::Schema::Result::Natrule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Natrule

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<natrule>

=cut

__PACKAGE__->table("natrule");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 number

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 enabled

  data_type: 'boolean'
  default_value: 1
  is_nullable: 1

=head2 origsrcset

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 origdstset

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 origsvcset

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 natsrcset

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 natdstset

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 natsvcset

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 nattype

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 source

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "number",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "enabled",
  { data_type => "boolean", default_value => 1, is_nullable => 1 },
  "origsrcset",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "origdstset",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "origsvcset",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "natsrcset",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "natdstset",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "natsvcset",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "nattype",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "source",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 natdstset

Type: belongs_to

Related object: L<Jemma::Schema::Result::Objectset>

=cut

__PACKAGE__->belongs_to(
  "natdstset",
  "Jemma::Schema::Result::Objectset",
  { id => "natdstset" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 natsrcset

Type: belongs_to

Related object: L<Jemma::Schema::Result::Objectset>

=cut

__PACKAGE__->belongs_to(
  "natsrcset",
  "Jemma::Schema::Result::Objectset",
  { id => "natsrcset" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 natsvcset

Type: belongs_to

Related object: L<Jemma::Schema::Result::Objectset>

=cut

__PACKAGE__->belongs_to(
  "natsvcset",
  "Jemma::Schema::Result::Objectset",
  { id => "natsvcset" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 origdstset

Type: belongs_to

Related object: L<Jemma::Schema::Result::Objectset>

=cut

__PACKAGE__->belongs_to(
  "origdstset",
  "Jemma::Schema::Result::Objectset",
  { id => "origdstset" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 origsrcset

Type: belongs_to

Related object: L<Jemma::Schema::Result::Objectset>

=cut

__PACKAGE__->belongs_to(
  "origsrcset",
  "Jemma::Schema::Result::Objectset",
  { id => "origsrcset" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 origsvcset

Type: belongs_to

Related object: L<Jemma::Schema::Result::Objectset>

=cut

__PACKAGE__->belongs_to(
  "origsvcset",
  "Jemma::Schema::Result::Objectset",
  { id => "origsvcset" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 source

Type: belongs_to

Related object: L<Jemma::Schema::Result::Source>

=cut

__PACKAGE__->belongs_to(
  "source",
  "Jemma::Schema::Result::Source",
  { id => "source" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2014-01-24 08:13:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hb6MjCLPhoTNHmKLnvTVSg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
