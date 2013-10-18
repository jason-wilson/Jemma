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

=head2 grpgrp_children

Type: has_many

Related object: L<Jemma::Schema::Result::Grpgrp>

=cut

__PACKAGE__->has_many(
  "grpgrp_children",
  "Jemma::Schema::Result::Grpgrp",
  { "foreign.child" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grpgrp_parents

Type: has_many

Related object: L<Jemma::Schema::Result::Grpgrp>

=cut

__PACKAGE__->has_many(
  "grpgrp_parents",
  "Jemma::Schema::Result::Grpgrp",
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

=head2 objectsetlists

Type: has_many

Related object: L<Jemma::Schema::Result::Objectsetlist>

=cut

__PACKAGE__->has_many(
  "objectsetlists",
  "Jemma::Schema::Result::Objectsetlist",
  { "foreign.grp" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-18 17:42:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AL6pfCDPYJUeSCi8wSsudw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
