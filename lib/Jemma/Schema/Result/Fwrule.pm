use utf8;
package Jemma::Schema::Result::Fwrule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Fwrule

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<fwrule>

=cut

__PACKAGE__->table("fwrule");

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

=head2 action

  data_type: 'text'
  is_nullable: 0

=head2 service

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sourceset

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 destination

  data_type: 'integer'
  is_foreign_key: 1
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
  "action",
  { data_type => "text", is_nullable => 0 },
  "service",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sourceset",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "destination",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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

=head2 destination

Type: belongs_to

Related object: L<Jemma::Schema::Result::Objectset>

=cut

__PACKAGE__->belongs_to(
  "destination",
  "Jemma::Schema::Result::Objectset",
  { id => "destination" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 service

Type: belongs_to

Related object: L<Jemma::Schema::Result::Objectset>

=cut

__PACKAGE__->belongs_to(
  "service",
  "Jemma::Schema::Result::Objectset",
  { id => "service" },
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

=head2 sourceset

Type: belongs_to

Related object: L<Jemma::Schema::Result::Objectset>

=cut

__PACKAGE__->belongs_to(
  "sourceset",
  "Jemma::Schema::Result::Objectset",
  { id => "sourceset" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-18 17:42:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0as0tjC06E9lhYQdHOcWgA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
