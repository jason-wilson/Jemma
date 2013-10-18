use utf8;
package Jemma::Schema::Result::Servicegrpgrp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Jemma::Schema::Result::Servicegrpgrp

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<servicegrpgrp>

=cut

__PACKAGE__->table("servicegrpgrp");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 servicegrp

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 service

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "servicegrp",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "service",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 service

Type: belongs_to

Related object: L<Jemma::Schema::Result::Service>

=cut

__PACKAGE__->belongs_to(
  "service",
  "Jemma::Schema::Result::Service",
  { id => "service" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 servicegrp

Type: belongs_to

Related object: L<Jemma::Schema::Result::Servicegrp>

=cut

__PACKAGE__->belongs_to(
  "servicegrp",
  "Jemma::Schema::Result::Servicegrp",
  { id => "servicegrp" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-18 17:42:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AXBQ/62FktFS5q7wPygUOg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
