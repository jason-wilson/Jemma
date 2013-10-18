use utf8;
package Jemma::Schema::Result::Objectset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Objectset

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<objectset>

=cut

__PACKAGE__->table("objectset");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 source

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
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

=head2 fwrule_destinations

Type: has_many

Related object: L<Jemma::Schema::Result::Fwrule>

=cut

__PACKAGE__->has_many(
  "fwrule_destinations",
  "Jemma::Schema::Result::Fwrule",
  { "foreign.destination" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fwrule_services

Type: has_many

Related object: L<Jemma::Schema::Result::Fwrule>

=cut

__PACKAGE__->has_many(
  "fwrule_services",
  "Jemma::Schema::Result::Fwrule",
  { "foreign.service" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fwrule_sourcesets

Type: has_many

Related object: L<Jemma::Schema::Result::Fwrule>

=cut

__PACKAGE__->has_many(
  "fwrule_sourcesets",
  "Jemma::Schema::Result::Fwrule",
  { "foreign.sourceset" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 objectsetlists

Type: has_many

Related object: L<Jemma::Schema::Result::Objectsetlist>

=cut

__PACKAGE__->has_many(
  "objectsetlists",
  "Jemma::Schema::Result::Objectsetlist",
  { "foreign.objectset" => "self.id" },
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
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-18 17:42:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kI/UnMh6Cpt8GZtKWZsTCQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
