package Chemistry::Bond;
$VERSION = '0.11';

=head1 NAME

Chemistry::Bond

=head1 SYNOPSIS

    use Chemistry::Bond;

    my $bond = new Chemistry::Bond(
	id => "b1", 
	type => '=', 
	atoms => [$a1, $a2]
        order => '2',
    );
    print $bond->print;

=head1 DESCRIPTION

This module includes objects to describe chemical bonds.
A bond is defined as a list of atoms (typically two), with some
associated properies.

=head2 Bond Attributes

In addition to common attributes such as id, name, and type, 
bonds have the order attribute. The bond order is a number, typically the
integer 1, 2, 3, or 4.

=cut

use 5.006001;
use strict;
use base qw(Chemistry::Obj);

my $N = 0;

=head1 METHODS

=over 4

=item Chemistry::Bond->new(name => value, ...)

Create a new Bond object with the specified attributes. Sensible defaults
are used when possible.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {
        id => $class->nextID(),
        type => '', 
        atoms => [],
        order => 1,
    } , $class;

    $self->$_($args{$_}) for (keys %args);
    $self;
}

sub nextID {
    "b".++$N; 
}

sub reset_id {
    $N = 0; 
}


=item $bond->order()

Sets or gets the bond order.

=cut

Chemistry::Obj::accessor('order');

=item $bond->length()

Returns the length of the bond, i.e., the distance between the two atom
objects in the bond. Returns zero if the bond does not have exactly two atoms.

=cut

sub length {
    my $self = shift;

    if (@{$self->{atoms}} == 2) {
	my $v = $self->{atoms}[1]{coords} - $self->{atoms}[0]{coords};
	return $v->length;
    } else {
	return 0;
    }
}

=item $bond->print

Convert the bond to a string representation. 

=cut

sub print {
    my $self = shift;
    my ($indent) = @_;
    my $l = sprintf "%.4g", $self->length;
    my $atoms = join " ", map {$_->id} $self->atoms;
    my $ret =  <<EOF;
$self->{id}:
    type: $self->{type}
    order: $self->{order}
    atoms: "$atoms"
    length: $l
EOF
    $ret .= "    attr:\n";
    $ret .= $self->print_attr($indent);
    $ret =~ s/^/"    "x$indent/gem;
    $ret;
}

=item $bond->atoms()

If called with no parameters, return a list of atoms in the bond.
If called with a list (or a reference to an array) of atom objects,
define the atoms in the bond and call $atom->add_bond for each atom
in the list.

=cut

sub atoms {
    my $self = shift;
    if (@_) {
        $self->{atoms} = ref $_[0] ? $_[0] : [@_];
        for my $a (@{$self->{atoms}}) { # add bond to each atom
            $a->add_bond($self);
        }
    } else {
        return (@{$self->{atoms}});
    }
}

1;

=back

=head1 SEE ALSO

L<Chemistry::Mol>, L<Chemistry::Atom>, L<Chemistry::Tutorial>

=head1 AUTHOR

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

