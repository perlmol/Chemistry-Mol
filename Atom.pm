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
use overload 
             '<=>'  => \&spaceship,
#	     '-' => \&minus,
;
use Carp;
use base qw(Chemistry::Obj);

use vars qw(@ELEMENTS %ELEMENTS);

my $N = 0; # Number of atoms created so far, used to generate default IDs.

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
	push @ret, $b->{to} unless $from && $b->{to} == $from;
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
	push @ret, $b->{bond} unless $from && $b->{to} == $from;
    }
    @ret;
}

=item $mol->print

Convert the atom to a string representation.

=cut

sub print {
    my $self = shift;
    my ($indent) = @_;

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
    $ret .= $self->print_attr($indent);
    $ret =~ s/^/"    "x$indent/gem;
    $ret;
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

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

