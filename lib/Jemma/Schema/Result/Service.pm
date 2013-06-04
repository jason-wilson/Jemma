use utf8;
package Jemma::Schema::Result::Service;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Service

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<service>

=cut

__PACKAGE__->table("service");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 protocol

  data_type: 'text'
  is_nullable: 0

=head2 ports

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
  "name",
  { data_type => "text", is_nullable => 0 },
  "protocol",
  { data_type => "text", is_nullable => 0 },
  "ports",
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

=head2 servicegrp_children

Type: has_many

Related object: L<Jemma::Schema::Result::Servicegrp>

=cut

__PACKAGE__->has_many(
  "servicegrp_children",
  "Jemma::Schema::Result::Servicegrp",
  { "foreign.child" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 servicegrp_parents

Type: has_many

Related object: L<Jemma::Schema::Result::Servicegrp>

=cut

__PACKAGE__->has_many(
  "servicegrp_parents",
  "Jemma::Schema::Result::Servicegrp",
  { "foreign.parent" => "self.id" },
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
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-06-04 13:50:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yWgNqLzQ7yf0GXGWOXlLEA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
