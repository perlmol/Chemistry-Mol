package Chemistry::Obj;

use strict;
=head1 NAME

Chemistry::Obj - Abstract chemistry object

=head1 SYNOPSIS

    use base "Chemistry::Obj";
    Chemistry::Obj::accessor('myattr1', 'myattr2');

=head1 DESCRIPTION

This module implements some generic methods that are used by Chemistry::Mol,
Chemistry::Atom, Chemistry::Bond, etc.

=head2 Common Attributes

There are some common attributes that may be found in molecules, bonds, and 
atoms, such as id, name, and type. They are all accessed through the methods
of the same name. For example, to get the id, call $obj->id; to set the id,
call $obj->id('new_id').

=over 4

=item id

Objects should have a unique ID. The user has the responsibility for uniqueness
if he assigns ids; otherwise a unique ID is assigned sequentially.

=item name

An arbitrary name for an object. The name doesn't need to be unique.

=item type

The interpretation of this attribute is not specified here, but it's typically 
used for bond orders and atom types.

=item attr

A space where the user can store any kind of information about the object.  The
accessor method for attr expects the attribute name as the first parameter, and
(optionally) the new value as the second parameter.

=cut

sub attr {
    my $self = shift;
    my $attr = shift;
    return $self->{attr}{$attr} unless @_;
    $self->{attr}{$attr} = shift;
    $self;
}

=back

=cut

use overload 
    '""' => "stringify",
    '<=>' => "spaceship";

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

sub print_attr {
    my $self = shift;
    my ($indent) = @_;
    my $ret = '';
    
    for my $attr (keys %{$self->{attr}}) {
        $ret .= "$attr: ".$self->attr($attr)."\n";
    }
    $ret and $ret =~ s/^/"    "x$indent/gem;
    $ret;
}


sub stringify {
    my $self = shift;
    $self->id;
}

sub spaceship {
    my ($a, $b) = @_;
    return $a->{id} cmp $b->{id};
}

accessor(qw(id name type));

1;

=head1 SEE ALSO

Chemistry::Atom, Chemistry::Bond, Chemistry::Mol

=head1 AUTHOR

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

