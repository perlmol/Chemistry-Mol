package Chemistry::Obj;
$VERSION = "0.10";

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

=head1 OTHER METHODS

=over

=item $obj->del_attr($attr_name)

Delete an attribute.

=cut

sub del_attr {
    my $self = shift;
    my $attr = shift;
    delete $self->{attr}{$attr};
}

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

=back

=head1 OPERATOR OVERLOADING

Chemistry::Obj overloads a couple of operators for convenience.

=over

=cut

use overload 
    '""' => "stringify",
    'cmp' => "obj_cmp",
    '0+', => "as_number",
    fallback => 1,
    ;

=item ""

The stringification operator. Stringify an object as its id. For example,
If an object $obj has the id 'a1', print "$obj" will print 'a1' instead of
something like 'Chemistry::Obj=HASH(0x810bbdc)'. If you really want to get 
the latter, you can call overload::StrVal($obj).

=cut

sub stringify {
    my $self = shift;
    $self->id;
}

sub as_number {
    $_[0];
}

=item cmp

Compare objects by ID. This automatically overloads eq, ne, lt, le, gt, and ge
as well. For example, $obj1 eq $obj2 returns true if both objects have the same
id, even if they are different objects with different memory addresses. In
contrast, $obj1 == $obj2 will return true only if $obj1 and $obj2 point to the
same object, with the same memory address.

=cut

sub obj_cmp {
    my ($a, $b) = @_;
    return $a->{id} cmp $b->{id};
}

=back

=cut

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

