use utf8;
package Jemma::Schema::Result::Ipaddrextra;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Ipaddrextra

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ipaddrextra>

=cut

__PACKAGE__->table("ipaddrextra");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 ipaddr

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 key

  data_type: 'text'
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ipaddr",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "key",
  { data_type => "text", is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 ipaddr

Type: belongs_to

Related object: L<Jemma::Schema::Result::Ipaddr>

=cut

__PACKAGE__->belongs_to(
  "ipaddr",
  "Jemma::Schema::Result::Ipaddr",
  { id => "ipaddr" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-23 13:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Dkt3poCoT1Ygtfx8/I1U+g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
