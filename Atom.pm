package Chemistry::Atom;
$VERSION = '0.21';
# $Id$

=head1 NAME

Chemistry::Atom

=head1 SYNOPSIS

    use Chemistry::Atom;

    my $atom = new Chemistry::Atom(
	id => 'a1',
	coords => [$x, $y, $z],
	symbol => 'Br'
    );

    print $atom->print;

=head1 DESCRIPTION

This module includes objects to describe chemical atoms. 
An atom is defined by its symbol and its coordinates.
Atomic coordinates are described by a Math::VectorReal
object, so that they can be easily used in vector operations.

=head2 Atom Attributes

In addition to common attributes such as id, name, and type, 
atoms have the following attributes, which are accessed or
modified through methods defined below: bonds, coords, Z, symbol.

In general, to get the value of a property use $atom->method without
any parameters. To set the value, use $atom->method($new_value).

=cut
# Considering to add the following attributes:
# mass_number (A)
# formal_charge

use 5.006;
use strict;
use Scalar::Util 'weaken';
use Math::VectorReal qw(O vector);
use Math::Trig;
use Carp;
use base qw(Chemistry::Obj Exporter);

our @EXPORT_OK = qw(distance angle dihedral angle_deg dihedral_deg);
our @EXPORT = ();
our %EXPORT_TAGS = (
      all  => [@EXPORT, @EXPORT_OK],
);


use vars qw(@ELEMENTS %ELEMENTS);

my $N = 0; # Number of atoms created so far, used to generate default IDs.

@ELEMENTS = qw(
    n
    H                                                                   He
    Li  Be                                          B   C   N   O   F   Ne
    Na  Mg                                          Al  Si  P   S   Cl  Ar
    K   Ca  Sc  Ti  V   Cr  Mn  Fe  Co  Ni  Cu  Zn  Ga  Ge  As  Se  Br  Kr
    Rb  Sr  Y   Zr  Nb  Mo  Tc  Ru  Rh  Pd  Ag  Cd  In  Sn  Sb  Te  I   Xe
    Cs  Ba
        La  Ce  Pr  Nd  Pm  Sm  Eu  Gd  Tb  Dy  Ho  Er  Tm  Yb
            Lu  Hf  Ta  W   Re  Os  Ir  Pt  Au  Hg  Tl  Pb  Bi  Po  At  Rn
    Fr  Ra
        Ac  Th  Pa  U   Np  Pu  Am  Cm  Bk  Cf  Es  Fm  Md  No
            Lr  Rf  Db  Sg  Bh  Hs  Mt  Ds  Uuu Uub Uut Uuq Uup Uuh Uus Uuo
);

for (my $i = 1; $i < @ELEMENTS; ++$i){
    $ELEMENTS{$ELEMENTS[$i]} = $i;
}
$ELEMENTS{D} = $ELEMENTS{T} = 1;

my %Atomic_masses = (
   "H" => 1.00794, "D" => 2.014101, "T" => 3.016049, "He" => 4.002602,
   "Li" => 6.941, "Be" => 9.012182, "B" => 10.811, "C" => 12.0107,
   "N" => 14.00674, "O" => 15.9994, "F" => 18.9984032, "Ne" => 20.1797,
   "Na" => 22.989770, "Mg" => 24.3050, "Al" => 26.981538, "Si" => 28.0855,
   "P" => 30.973761, "S" => 32.066, "Cl" => 35.4527, "Ar" => 39.948,
   "K" => 39.0983, "Ca" => 40.078, "Sc" => 44.955910, "Ti" => 47.867,
   "V" => 50.9415, "Cr" => 51.9961, "Mn" => 54.938049, "Fe" => 55.845,
   "Co" => 58.933200, "Ni" => 58.6934, "Cu" => 63.546, "Zn" => 65.39,
   "Ga" => 69.723, "Ge" => 72.61, "As" => 74.92160, "Se" => 78.96,
   "Br" => 79.904, "Kr" => 83.80, "Rb" => 85.4678, "Sr" => 87.62,
   "Y" => 88.90585, "Zr" => 91.224, "Nb" => 92.90638, "Mo" => 95.94,
   "Tc" => 98, "Ru" => 101.07, "Rh" => 102.90550, "Pd" => 106.42,
   "Ag" => 107.8682, "Cd" => 112.411, "In" => 114.818, "Sn" => 118.710,
   "Sb" => 121.760, "Te" => 127.60, "I" => 126.90447, "Xe" => 131.29,
   "Cs" => 132.90545, "Ba" => 137.327, "La" => 138.9055, "Ce" => 140.116,
   "Pr" => 140.90765, "Nd" => 144.24, "Pm" => 145, "Sm" => 150.36,
   "Eu" => 151.964, "Gd" => 157.25, "Tb" => 158.92534, "Dy" => 162.50,
   "Ho" => 164.93032, "Er" => 167.26, "Tm" => 168.93421, "Yb" => 173.04,
   "Lu" => 174.967, "Hf" => 178.49, "Ta" => 180.9479, "W" => 183.84,
   "Re" => 186.207, "Os" => 190.23, "Ir" => 192.217, "Pt" => 195.078,
   "Au" => 196.96655, "Hg" => 200.59, "Tl" => 204.3833, "Pb" => 207.2,
   "Bi" => 208.98038, "Po" => 209, "At" => 210, "Rn" => 222,
   "Fr" => 223, "Ra" => 226, "Ac" => 227, "Th" => 232.038,
   "Pa" => 231.03588, "U" => 238.0289, "Np" => 237, "Pu" => 244,
   "Am" => 243, "Cm" => 247, "Bk" => 247, "Cf" => 251,
   "Es" => 252, "Fm" => 257, "Md" => 258, "No" => 259,
   "Lr" => 262, "Rf" => 261, "Db" => 262, "Sg" => 266,
   "Bh" => 264, "Hs" => 269, "Mt" => 268, "Ds" => 271,
);

=head1 METHODS

=over 4

=item Chemistry::Atom->new(name => value, ...)

Create a new Atom object with the specified attributes. Sensible defaults
are used when possible.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless {
        id => $class->nextID(),
        coords => vector(0, 0, 0),
        Z => 0,
        symbol => '',
        bonds => [],
    }, $class;

    $self->$_($args{$_}) for (keys %args);
    $self;
}

sub nextID {
    "a".++$N; 
}

sub reset_id {
    $N = 0; 
}


=item $atom->Z($new_Z)

Sets and returns the atomic number (Z). If the symbol of the atom doesn't
correspond to a known element, Z = undef.

=cut

sub Z {
    my $self = shift;

    if(@_) {
        $self->{symbol} = $ELEMENTS[$_[0]];
        return $self->{Z} = $_[0];
    } else {
        return $self->{Z};
    }
}


=item $atom->symbol($new_symbol)

Sets and returns the atomic symbol.

=cut

sub symbol {
    my $self = shift;

    if(@_) {
	$_[0] =~ s/ //g;
        $self->{Z} = $ELEMENTS{$_[0]};
        return $self->{symbol} = $_[0];
    } else {
        return $self->{symbol};
    }
}

=item $atom->mass($new_mass)

Sets and returns the atomic mass in atomic mass units. By default, relative
atomic masses from the 1995 IUPAC recommendation are used. (Table stolen from
the Chemistry::MolecularMass module by Maksim A. Khrapov).

=cut

sub mass {
    my ($self, $mass) = @_;
    if(defined $mass) {
        $self->{mass} = $mass;
    } else {
        if (exists $self->{mass}) {
            $mass = $self->{mass};
        } else {
            $mass = $Atomic_masses{$self->symbol};
        }
    }
    $mass;
}

=item $atom->coords([$x, $y, $z])

Sets the atom's coordinates, and returns a Math::VectorReal object.
It can take as a parameter a Math::VectorReal object, a reference to an 
array, or the list of coordinates.

=cut

sub coords {
    my $self = shift;

    if(@_) {
        if (UNIVERSAL::isa($_[0], "Math::VectorReal")) {
            return $self->{coords} = $_[0];
        } elsif (ref $_[0] eq "ARRAY") {
            return $self->{coords} = vector(@{$_[0]});
        } else {
            return $self->{coords} = vector(@_);
        }
    } else {
        return $self->{coords};
    }
}

=item $atom->add_bond($bond)

Adds a new bond to the atom, as defined by the Bond object $bond.

=cut

sub add_bond {
    my $self = shift;
    my $bond = shift;

    for my $atom (@{$bond->{atoms}}){ #for each atom...
        if ($atom ne $self) {
            my $b = {to=>$atom, bond=>$bond};
            weaken($b->{to});
            weaken($b->{bond});
            push @{$self->{bonds}}, $b;
        }
    }
}

sub _weaken {
    my $self = shift;
    for my $b (@{$self->{bonds}}) {
        weaken($b->{to});
        weaken($b->{bond});
    }
}

# This method is private. Bonds should be deleted from the 
# mol object. These methods should only be called by 
# $bond->delete_atoms, which is called by $mol->delete_bond
sub delete_bond {
    my ($self, $bond) = @_;
    $self->{bonds} = [ grep { $_->{bond} ne $bond } @{$self->{bonds}} ];
}

=item $atom->delete

Calls $mol->delete_atom($atom) on the atom's parent molecule. Note that an atom
should belong to only one molecule or strange things may happen.

=cut

sub delete {
    my ($self) = @_;
    $self->{parent}->delete_atom($self);
}

sub parent {
    my $self = shift;
    if (@_) {
        ($self->{parent}) = @_;
        weaken($self->{parent});
        $self;
    } else {
        $self->{parent};
    }
}

=item $atom->neighbors([$from])

Return a list of neighbors. If an atom object $from is specified, it will be
excluded from the list.

=cut

sub neighbors {
    my $self = shift;
    my $from = shift;
    my @ret = ();

    for my $b (@{$self->{bonds}}) {
	push @ret, $b->{to} unless $from && $b->{to} eq $from;
    }
    @ret;
}

=item $atom->bonds([$from])

Return a list of bonds. If an atom object $from is specified, it will be
excluded from the list.

=cut

sub bonds {
    my $self = shift;
    my $from = shift;
    my @ret = ();

    for my $b (@{$self->{bonds}}) {
	push @ret, $b->{bond} unless $from && $b->{to} ne $from;
    }
    @ret;
}

=item ($distance, $closest_atom) = $atom->distance($obj)

Returns the minimum distance to $obj, which can be an atom, a molecule, or a
vector. In scalar context it returns only the distance; in list context it
also returns the closest atom found.

=cut

sub distance {
    my $self = shift;
    my $obj = shift;
    my $min_length;
    my $closest_atom = $obj;

    if ($obj->isa('Chemistry::Atom')) {
        my $v = $self->coords - $obj->coords;
        $min_length = $v->length;
    } elsif ($obj->isa('Math::VectorReal')) {
        my $v = $self->coords - $obj;
        $min_length = $v->length;
    } elsif ($obj->isa('Chemistry::Mol')) {
        my @atoms = $obj->atoms;
        my $a = shift @atoms or return undef; # ensure there's at least 1 atom
        $min_length = $self->distance($a);
        $closest_atom = $a;
        for $a (@atoms) {
            my $l = $self->distance($a);
            $min_length = $l, $closest_atom = $a if $l < $min_length;
        }
    } else {
        croak "atom->distance() undefined for objects of type '", ref $obj,"'";
    }
    wantarray ? ($min_length, $closest_atom) : $min_length;
}

=item $atom->angle($atom2, $atom3)

Returns the angle in radians between the atoms involved. $atom2 is the atom in
the middle. Can also be called as Chemistry::Atom::angle($atom1, $atom2, $atom3);

=cut

# $a2 is the one in the center
sub angle {
    @_ == 3 or croak "Chemistry::Atom::angle requires three atoms!\n";
    my @c;
    for my $a (@_) { # extract coordinates
        push @c, $a->isa("Chemistry::Atom") ? $a->coords :
            $a->isa("Math::VectorReal") ? $a : 
                croak "angle: $a is neither an atom nor a vector!\n";
    }
    my $v1 = $c[0] - $c[1];
    my $v2 = $c[2] - $c[1];
    acos(($v1 . $v2) / ($v1->length * $v2->length));
}

=item $atom->angle_deg($atom2, $atom3)

Same as angle(), but returns the value in degrees.

=cut

sub angle_deg {
    rad2deg(angle(@_));
}

=item $atom->dihedral($atom2, $atom3, $atom4)

Returns the dihedral angle in radians between the atoms involved.  Can also be
called as Chemistry::Atom::dihedral($atom1, $atom2, $atom3, $atom4);

=cut

sub dihedral {
    @_ == 4 or croak "Chemistry::Atom::dihedral requires four atoms!\n";
    my @c;
    for my $a (@_) { # extract coordinates
        push @c, $a->isa("Chemistry::Atom") ? $a->coords :
            $a->isa("Math::VectorReal") ? $a : 
                croak "angle: $a is neither an atom nor a vector!\n";
    }
    my $v1 = $c[0] - $c[1];
    my $v2 = $c[2] - $c[1];
    my $v3 = $c[3] - $c[2];
    my $x1 = $v1 x $v2;
    my $x2 = $v3 x $v2;
    my $abs_dih = angle($x1, O(), $x2);
    $v1 . $x2 > 0 ? $abs_dih : -$abs_dih;
}

=item $atom->dihedral_deg($atom2, $atom3, $atom4)

Same as dihedral(), but returns the value in degrees.

=cut

sub dihedral_deg {
    rad2deg(dihedral(@_));
}

=item $atom->print

Convert the atom to a string representation.

=cut

sub print {
    my $self = shift;
    my ($indent) = @_;

    $indent ||= 0;
    my $bonds = join " ", map {$_->id} $self->bonds;
    my $neighbors = join " ", map {$_->id} $self->neighbors;
    my $coords = $self->{coords}->stringify(
    'x3: %g
    y3: %g
    z3: %g'
    );

    my $ret = <<EOF;
$self->{id}:
    symbol: $self->{symbol}
    name  : $self->{name}
    $coords
    bonds: "$bonds"
    neighbors: "$neighbors"
EOF
    $ret .= "    attr:\n";
    $ret .= $self->print_attr($indent+2);
    $ret =~ s/^/"    "x$indent/gem;
    $ret;
}

1;

=back

=head1 VERSION

0.21

=head1 SEE ALSO

L<Chemistry::Mol>, L<Chemistry::Bond>, 
L<Math::VectorReal>, L<Chemistry::Tutorial>

The PerlMol website L<http://www.perlmol.org/>

=head1 AUTHOR

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

