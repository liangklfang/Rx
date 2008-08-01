use strict;
use warnings;
package Data::Rx::CoreType::map;
use base 'Data::Rx::CoreType';

use Scalar::Util ();

sub authority { '' }
sub subname   { 'map' }

sub new {
  my ($class, $arg) = @_;

  Carp::croak("unknown arguments to new") unless
  Data::Rx::Util->_x_subset_keys_y($arg, { required => 1, optional => 1 });

  my $content_schema = {};

  TYPE: for my $type (qw(required optional)) {
    next TYPE unless my $entries = $arg->{$type};

    for my $entry (keys %$entries) {
      Carp::croak("$entry appears in both required and optional")
        if $content_schema->{ $entry };

      $content_schema->{ $entry } = {
        optional => $type eq 'optional',
        schema   => Data::Rx->new->make_schema($entries->{ $entry }),
      };
    }
  };

  return bless { content_schema => $content_schema } => $class;
}

sub check {
  my ($self, $value) = @_;

  return unless
    ! Scalar::Util::blessed($value) and ref $value eq 'HASH';

  my $c_schema = $self->{content_schema};
  return unless Data::Rx::Util->_x_subset_keys_y($value, $c_schema);

  for my $key (keys %$c_schema) {
    my $check = $c_schema->{$key};
    return if not $check->{optional} and not exists $value->{$key};
    return if exists $value->{$key} and ! $check->{schema}->check($value->{$key});
  }

  return 1;
}

1;
