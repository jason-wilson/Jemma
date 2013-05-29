use utf8;
package Jemma::Schema::Result::Grp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Grp

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<grp>

=cut

__PACKAGE__->table("grp");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 parent

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 source

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "parent",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "source",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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
  { "foreign.parent" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ipgrps

Type: has_many

Related object: L<Jemma::Schema::Result::Ipgrp>

=cut

__PACKAGE__->has_many(
  "ipgrps",
  "Jemma::Schema::Result::Ipgrp",
  { "foreign.grp" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 parent

Type: belongs_to

Related object: L<Jemma::Schema::Result::Grp>

=cut

__PACKAGE__->belongs_to(
  "parent",
  "Jemma::Schema::Result::Grp",
  { id => "parent" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-29 15:58:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1ZzPcRTcny1FnTIP6Hb5mQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
