package Chemistry::Obj;

=head1 NAME

Chemistry::Obj - Abstract chemistry object

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Common Attributes

There are some common attributes that may be found in molecules, bonds, and 
atoms, such as id, name, and type.

=over 4

=item id

Objects should have a unique ID. The user has the responsibility for uniqueness
if he assigns ids; otherwise a unique ID is assigned sequentially.

=item name

An arbitrary name for an object. The name doesn't need to be unique.

=item type

The interpretation of this attribute is not specified here, but it's typically 
used for bond orders and atom types.

=back

=cut

# A generic class attribute set/get method generator
sub accessor {
    my $pkg = caller;
    no strict 'refs';
    for my $attribute (@_) {
        *{"${pkg}::$attribute"} =
          sub {
              my $self = shift;
              return $self->{$attribute} unless @_;
              $self->{$attribute} = shift;
              return $self;
          };
    }
}

sub attr {
    my $self = shift;
    my $attr = shift;
    return $self->{attr}{$attr} unless @_;
    $self->{attr}{$attr} = shift;
    $self;
}

accessor(qw(id name type));

1;
