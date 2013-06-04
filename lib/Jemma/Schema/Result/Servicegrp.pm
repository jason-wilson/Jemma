use utf8;
package Jemma::Schema::Result::Servicegrp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Servicegrp

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<servicegrp>

=cut

__PACKAGE__->table("servicegrp");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 parent

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 child

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "parent",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "child",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 child

Type: belongs_to

Related object: L<Jemma::Schema::Result::Service>

=cut

__PACKAGE__->belongs_to(
  "child",
  "Jemma::Schema::Result::Service",
  { id => "child" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 parent

Type: belongs_to

Related object: L<Jemma::Schema::Result::Service>

=cut

__PACKAGE__->belongs_to(
  "parent",
  "Jemma::Schema::Result::Service",
  { id => "parent" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-06-04 13:23:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WeB2ui32EtS2r+R8A1BTew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
