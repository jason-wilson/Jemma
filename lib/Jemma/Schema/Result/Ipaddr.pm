use utf8;
package Jemma::Schema::Result::Ipaddr;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Ipaddr

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ipaddr>

=cut

__PACKAGE__->table("ipaddr");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 start

  data_type: 'integer'
  is_nullable: 0

=head2 end

  data_type: 'integer'
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
  "start",
  { data_type => "integer", is_nullable => 0 },
  "end",
  { data_type => "integer", is_nullable => 0 },
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

=head2 ipaddrextras

Type: has_many

Related object: L<Jemma::Schema::Result::Ipaddrextra>

=cut

__PACKAGE__->has_many(
  "ipaddrextras",
  "Jemma::Schema::Result::Ipaddrextra",
  { "foreign.ipaddr" => "self.id" },
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
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-05-23 13:11:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z9r/HVQWlzhK75zWmY3+ag


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
