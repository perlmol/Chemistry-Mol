package Chemistry::Atom;

=head1 NAME

Chemistry::Atom

=head1 SYNOPSIS

    use Chemistry::Atom;

    my $atom = new Chemistry::Atom(
	id => 'a1',
	coords => [$x, $y, $z],
	symbol => 'Br'
    );
    
    $atom->add_bond($b);

    print $atom;

=head1 DESCRIPTION

This module includes objects to describe chemical atoms. 
An atom is defined by its symbol and its coordinates.
Atomic coordinates are described by a Math::VectorReal
object, so that they can be easily used in vector operations.

=head2 Atom Attributes

In addition to common attributes such as id, name, and type, 
atoms have the following attributes, which are accessed or
modified through methods defined below: bonds, coords, Z, symbol.

In general, to get the value of a property use $mol->method without
any parameters. To set the value, use $mol->method($new_value).

=cut


use strict;
use Math::VectorReal;
use overload '""' => \&stringify,
             '<=>'  => \&spaceship,
#	     '-' => \&minus,
;
use Carp;
use base Chemistry::Obj;

use vars qw(%READ_ONLY @ELEMENTS %ELEMENTS);

my $N = 0; # Number of atoms created so far, used to generate default IDs.
%READ_ONLY = (bonds => 1);

@ELEMENTS = qw(
    n
    H                                                                   He
    Li  Be                                          B   C   N   O   F   Ne
    Na  Mg                                          Al  Si  P   S   Cl  Ar
    K   Ca  Sc  Ti  V   Cr  Mn  Fe  Co  Ni  Cu  Zn  Ga  Ge  As  Se  Br  Kr
    Rb  Sr  Y   Zr  Nb  Mo  Tc  Ru  Rh  Pd  Ag  Cd  In  Sn  Sb  Te  I   Xe
);

for (my $i = 1; $i < @ELEMENTS; ++$i){
    $ELEMENTS{$ELEMENTS[$i]} = $i;
}
$ELEMENTS{D} = $ELEMENTS{T} = 1;

=head1 METHODS

=over 4

=item Chemistry::Atom->new(name => value, ...)

Create a new Atom object with the specified attributes. Sensible defaults
are used when possible.

=cut

sub new {
    my $class = shift;

    my $newatom = bless {
        id => "a".++$N,
        coords => vector(0, 0, 0),
        Z => 0,
        symbol => '',
        bonds => [],
    }, $class;

    my %arg = @_;

    foreach (keys %arg){
        $newatom->$_($arg{$_});
    }
    return $newatom;
}

sub nextID {
    "a".++$N; 
}


=item $atom->Z($new_Z)

Sets and returns Z. If the symbol of the atom doesn't correspond to
a known element, Z = undef.

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

=item $atom->coords([$x, $y, $z])

Sets the atom's coordinates, and returns a Math::VectorReal object.

=cut

sub coords {
    my $self = shift;

    if(@_) {
        return $self->{coords} = vector(@{$_[0]});
    } else {
        return $self->{coords};
    }
}

=item $atom->add_bond($bond)

Adds a new bond to the atom, as defined by the Bond object $bond.

=cut

sub add_bond {
    my $self = shift;
    my $b = shift;

    for my $a (@{$b->{atoms}}){ #for each atom...
        push @{$self->{bonds}}, {to=>$a, bond=>$b} if $a != $self;
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
	push @ret, $b->{to} unless $b->{to} == $from;
    }
    @ret;
}


=back

=head1 OPERATOR OVERLOADING

Chemistry::Atom overloads a few operators for convenience.

=over 4

=item $mol->print

Convert the atom to a string representation. Mainly used for debugging.

=cut

sub print {
    my $self = shift;
    my $bonds = "";
    my $neighbors = "";

    for (@{$self->{bonds}}){
        $bonds .= $_->{bond}{id}." ";
        $neighbors .= $_->{to}{id}." ";
    }

    my $coords = $self->{coords}->stringify(
	'<float builtin="x3">%g</float>\n
        <float builtin="y3">%g</float>\n
        <float builtin="z3">%g</float>'
    );

    return <<EOF;
    <atom id="$self->{id}">
        <string builtin="elementType">$self->{symbol}</string>
        $coords
        <string name="bonds">$bonds</string>
        <string name="neighbors">$neighbors</string>
    </atom>
EOF
}

sub stringify {
    my $self = shift;
    $self->{id};
}

sub spaceship {
#    my $self = shift;
    my ($a, $b) = @_;

#    print "ref a (id = $a->{id}) = ", ref($a), "\n";
#    print "ref b (id = $b->{id}) = ", ref($b), "\n";

    return $a->{id} cmp $b->{id};
}


1;

=back

=head1 SEE ALSO

Chemistry::Mol, Chemistry::Bond, Math::VectorReal

=head1 AUTHOR

Ivan Tubert-Brohman <ivan@tubert.org>

=head1 VERSION

$Id$

=cut

