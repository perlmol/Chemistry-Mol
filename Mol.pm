package Chemistry::Mol;
$VERSION = '0.20';
# $Id$

=head1 NAME

Chemistry::Mol - Molecule object toolkit

=head1 SYNOPSIS

    use Chemistry::Mol;

    $mol = Chemistry::Mol->new(id => "mol_id", name => "my molecule");
    $c = $mol->new_atom(symbol => "C", coords => [0,0,0]); 
    $o = $mol->new_atom(symbol => "O", coords => [0,0,1.23]); 
    $mol->new_bond(atoms => [$c, $o], order => 3);

    print $mol->print;

=head1 DESCRIPTION

This package, along with Chemistry::Atom and Chemistry::Bond, includes basic
objects and methods to describe molecules. 

The core methods try not to enforce a particular convention.  This means that
only a minimal set of attributes is provided by default, and some attributes
have very loosely defined meaning. This is because each program and file type
has different idea of what each concept (such as bond and atom type) means.
Bonds are defined as a list of atoms (typically two) with an arbitrary type.
Atoms are defined by a symbol and a Z, and may have 3D coordinates (2D and
internal coming soon).

=cut

use 5.006001;
use strict;
use Chemistry::Atom;
use Chemistry::Bond;
use Carp;
use base qw(Chemistry::Obj Exporter);
use Storable 'dclone';

our @EXPORT_OK = qw(read_mol);
our @EXPORT = ();
our %EXPORT_TAGS = (
      all  => [@EXPORT, @EXPORT_OK],
);



my %FILE_FORMATS = ();
my $N = 0; # atom ID counter

=head1 METHODS

See also Chemistry::Obj for generic attributes.

=over 4

=item Chemistry::Mol->new(name => value, ...)

Create a new Mol object with the specified attributes. 

    $mol = Chemistry::Mol->new(id => 'm123', name => 'my mol')

is the same as

    Chemistry::Mol->new()
    $mol->id('m123')
    $mol->name('my mol')

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {
	id => $class->nextID,
	byId => {}, 
	atoms => [], 
	bonds => [], 
	name => "",
    }, ref $class || $class;
    $self->$_($args{$_}) for (keys %args);
    return $self;
}

sub nextID {
    "mol".++$N; 
}

sub reset_id {
    $N = 0; 
}

=item $mol->add_atom($atom, ...)

Add one or more Atom objects to the molecule. Returns the last atom added.

=cut

sub add_atom {
    my $self = shift;
    for my $atom (@_){
        #if ($self->by_id($atom->id)) {
            #croak "Duplicate ID when adding atom '$atom' to mol '$self'";
        #}
        push @{$self->{atoms}}, $atom;
        $self->{byId}{$atom->id} = $atom;
        $atom->parent($self);
    }
    $_[-1];
}

=item $mol->new_atom(name => value, ...)

Shorthand for $mol->add_atom(Chemistry::Atom->new(name => value, ...));
It has the disadvantage that it doesn't let you create a subclass of 
Chemistry::Atom.

=cut

sub new_atom {
    my $self = shift;
    $self->add_atom(Chemistry::Atom->new(@_));
}

=item $mol->delete_atom($atom, ...)

Deletes an atom from the molecule. It automatically deletes all the bonds
in which the atom participates as well.

=cut

# mol deletes bonds that belonged to atom
# mol deletes atom

sub delete_atom {
    my $self = shift;
    for my $i (@_){
        my ($atom, $index);
        if (ref $i) {
            $atom = $i;
            $index = $self->get_atom_index($atom)    
                or croak "$self->delete_atom: no such atom $atom\n";
        } else {
            $index = $i;
            $atom = $self->atoms($index)
                or croak "$self->delete_atom: no such atom $index\n";
        }
        my $id = $atom->id;
        $self->delete_bond($atom->bonds);
        delete $self->{byId}{$id};
        splice @{$self->{atoms}}, $index - 1, 1;
    }
}

=item $mol->add_bond($bond, ...)

Add one or more Bond objects to the molecule. Returns the last bond added.

=cut

sub add_bond {
    my $self = shift;
    for my $bond (@_){
        #if ($self->by_id($bond->id)) {
            #croak "Duplicate ID when adding bond '$bond' to mol '$self'";
        #}
        push @{$self->{bonds}}, $bond;
	$self->{byId}{$bond->id} = $bond;
        $bond->parent($self);
    }
    $_[-1];
}

=item $mol->new_bond(name => value, ...)

Shorthand for $mol->add_bond(Chemistry::Bond->new(name => value, ...));
It has the disadvantage that it doesn't let you create a subclass of 
Chemistry::Bond.

=cut

sub new_bond {
    my $self = shift;
    $self->add_bond(Chemistry::Bond->new(@_));
}

sub get_bond_index {
    my ($self, $bond) = @_;
    my $i;
    for ($self->bonds) {
        ++$i;
        return $i if ($_ eq $bond);
    }
    undef;
}

sub get_atom_index {
    my ($self, $atom) = @_;
    my $i;
    for ($self->atoms) {
        ++$i;
        return $i if ($_ eq $atom);
    }
    undef;
}

=item $mol->delete_bond($bond, ...)

Deletes a bond from the molecule.

=cut

# mol deletes bond
# bond tells atoms involved to forget about it

sub delete_bond {
    my $self = shift;
    for my $i (@_){
        my ($bond, $index);
        if (ref $i) {
            $bond = $i;
            $index = $self->get_bond_index($bond)
                or croak "$self->delete_bond: no such bond $bond\n";
        } else {
            $index = $i;
            $bond = $self->bonds($index)
                or croak "$self->delete_bond: no such bond $index\n";
        }
        my $id = $bond->id;
        delete $self->{byId}{$id};
        splice @{$self->{bonds}}, $index - 1, 1;
        $bond->delete_atoms;
    }
}

=item $mol->by_id($id)

Return the atom or bond object with the corresponding id.

=cut

sub by_id {
    my $self = shift;
    my ($id) = @_;
    $self->{byId}{$id};
}

=item $mol->atoms($n1, ...)

Returns the atoms with the given indices, or all by default. 
Indices start from one, not from zero.

=cut

sub atoms {
    my $self = shift;
    my @ats = map {$_ - 1} @_;
    if (@ats) {
        @{$self->{atoms}}[@ats];
    } else {
        @{$self->{atoms}};
    }
}

=item $mol->atoms_by_name($name)

Returns the atoms with the given name (treated as an anchored regular
expression).

=cut

sub atoms_by_name {
    my $self = shift;
    my $re = qr/^$_[0]$/;
    no warnings;
    my @ret = grep {$_->name =~ $re} $self->atoms;
    #my ($re) = @_; # 5.004 hack
    #my @ret = grep {defined $_->name and $_->name =~ /$re/o} $self->atoms;
    wantarray ? @ret : $ret[0];
}

=item $mol->bonds($n1, ...)

Returns the bonds with the given indices, or all by default.
Indices start from one, not from zero.

=cut

sub bonds {
    my $self = shift;
    my @bonds = map {$_ - 1} @_;
    if (@bonds) {
        @{$self->{bonds}}[@bonds];
    } else {
        @{$self->{bonds}};
    }
}

=item $mol->print(option => value...)

Convert the molecule to a string representation. If no options are given, 
a default YAML-like format is used (this may change in the future). Otherwise,
the format should be specified by using the C<format> option.

=cut

sub print {
    my $self = shift;
    my (%opts) = @_;
    my $ret;
    local $" = ""; #"

    if ($opts{format}) {
        return $self->formats($opts{format})->write_string($self, %opts);
    }
    # else use default printout 
    $ret = <<END;
$self->{id}:
    name: $self->{name}
END
    $ret .= "    attr:\n";
    $ret .= $self->print_attr(2);
    $ret .= "    atoms:\n";
    for my $a (@{$self->{atoms}}) { $ret .= $a->print(2) }
    $ret .= "    bonds:\n";
    for my $b (@{$self->{bonds}}) { $ret .= $b->print(2) }
    $ret;
}

=item $mol->parse($string, option => value...)

Parse the molecule encoded in $string. The format should be specified
with the the C<format> option; otherwise, it will be guessed.

=cut

sub parse {
    my $self = shift;
    my $s = shift;
    my %opts = (mol_class => $self, @_);

    if ($opts{format}) {
        return $self->formats($opts{format})->parse_string($s, %opts);
    } else {
        croak "Parse does not support autodetection yet.",
            "Please specify a format.";
    }
    undef;
}

=item Chemistry::Mol->read($fname, option => value ...)

Read a file and return a list of Mol objects, or croaks if there
was a problem. The type of file will be guessed if not
specified via the C<format> option.

Note that only registered file readers will be used. Readers may
be registered using register_type(); modules that include readers
(such as Chemistry::File::PDB) usually register them automatically.

=cut

sub read_mol { # for backwards compatibility
    my ($fname, $type) = shift;
    __PACKAGE__->read($fname, format => $type);
}

sub read {
    my $self = shift;
    my $fname = shift;
    my %opts = (mol_class => $self, @_);

    if ($opts{format}) {
        return $self->formats($opts{format})->parse_file($fname, %opts);
    } else { # guess format
        for my $type ($self->formats) {
            if ($self->formats($type)->file_is($fname)) {
                return $self->formats($type)->parse_file($fname, %opts);
            }
        }
    }
    croak "Couldn't guess format of file '$fname'";
}

=item $mol->write($fname, option => value ...)

Write a molecule file, or croak if there
was a problem. The type of file will be guessed if not
specified via the C<format> option.

Note that only registered file formats will be used. 

=cut

sub write {
    my ($self, $fname, %opts) = (@_);

    if ($opts{format}) {
        return $self->formats($opts{format})->write_file(@_);
    } else { # guess format
	for my $type ($self->formats) {
            if ($self->formats($type)->name_is($fname)) {
                return $self->formats($type)->write_file(@_);
	    }
	}
    }
    croak "Couldn't guess format for writing file '$fname'";
}

=item Chemistry::Mol->register_format($name, $ref)

Register a file type. The identifier $name must be unique.
$ref is either a class name (a package) or an object that complies
with the L<Chemistry::File> interface (e.g., a subclass of Chemistry::File).
If $ref is omitted, the calling package is used automatically. More than one
format can be registered at a time, but then $ref must be included for each
format (e.g., Chemistry::Mol->register_format(format1 => "package1", format2 =>
package2).

The typical user doesn't have to care about this function. It is used
automatically by molecule file I/O modules.

=cut

sub register_format {
    my $class = shift;
    if (@_ == 1) {
        $FILE_FORMATS{$_[0]} = caller;
        return;
    }
    my %opts = @_;
    $FILE_FORMATS{$_} = $opts{$_} for keys %opts;
}

=item Chemistry::Mol->formats

Returns a list of the file formats that have been installed by
register_type()

=cut

sub formats {
    my $self = shift;
    if (@_) {
        my ($type) = @_;
        my $file_class = $FILE_FORMATS{$type};
        unless ($file_class) {
            croak "No class installed for type '$type'";
        }
        return $file_class;
    } else {
        return sort keys %FILE_FORMATS;
    }
}

=item $mol->mass

Return the molar mass.

=cut

sub mass {
    my ($self) = @_;
    my $mass = 0;
    for my $atom ($self->atoms) {
        $mass += $atom->mass;
    }
    $mass;
}

=item $mol->formula_hash

Returns a hash reference describing the molecular formula. For methane it would
return { C => 1, H => 4 }.

=cut

sub formula_hash {
    my ($self) = @_;
    my $formula = {};
    for my $atom ($self->atoms) {
        $formula->{$atom->symbol}++;
    }
    $formula;
}

=item $mol->formula($format)

Returns a string with the formula. The format can be specified as a printf-like
string with the control sequences specified in the L<Chemistry::File::Formula>
documentation.

=cut

sub formula {
    my ($self, $format) = @_;
    require Chemistry::File::Formula;
    $self->print(format => "formula", formula_format => $format);
}

=item my $mol2 = $mol->clone;

Makes a copy of a molecule.

=cut

sub clone {
    my ($self) = @_;
    my $clone = dclone $self;
    for ($clone->atoms, $clone->bonds) {
        $_->_weaken;
    }
    $clone;
}

=item ($distance, $atom_here, $atom_there) = $mol->distance($obj)

Returns the minimum distance to $obj, which can be an atom, a molecule, or a
vector. In scalar context it returns only the distance; in list context it
also returns the atoms involved. The current implementation for calculating
the minimum distance between two molecules compares every possible pair of
atoms, so it's not efficient for large molecules.

=cut

sub distance {
    my ($self, $other) = @_;
    if ($other->isa("Chemistry::Mol")) {
        my @atoms = $self->atoms;
        my $atom = shift @atoms or return undef; # need at least one atom
        my $closest_here = $atom;
        my ($min_length, $closest_there) = $atom->distance($other);
        for $atom (@atoms) {
            my ($d, $o) = $atom->distance($other);
            if ($d < $min_length) {
                ($min_length, $closest_there, $closest_here) = ($d, $o, $atom);
            }
        }
        return wantarray ? 
            ($min_length, $closest_here, $closest_there) : $min_length;
    } elsif ($other->isa("Chemistry::Atom")) {
        return $other->distance($self);
    } elsif ($other->isa("Math::VectorReal")) {
        return Chemistry::Atom->new(coords => $other)->distance($self);
    }
}

=item my $bigmol = Chemistry::Mol->combine($mol1, $mol2, ...)

=item $mol1->combine($mol2, $mol3, ...)

Combines several molecules in one bigger molecule. If called as a class method,
as in the first example, it returns a new combined molecule without altering
any of the parameters. If called as an instance method, as in the second
example, all molecules are combined into $mol1 (but $mol2, $mol3, ...) are not
altered.

=cut

# joins several molecules into one
# Does not touch the original copy.
sub combine {
    my ($self, @others) = @_;
    my $mol;
    if (ref $self) {
        $mol = $self;
    } else {
        $mol = $self->new;
    }
    for my $other (@others) {
        my $mol2 = $other->clone;
        for my $atom ($mol2->atoms) {
            $mol->add_atom($atom);
        }
        for my $bond ($mol2->bonds) {
            $mol->add_bond($bond);
        }
    }
    $mol;
}

=item my @mols = $mol->separate

Separates a molecule into "connected fragments". The original object is not
modified; the fragments are clones of the original ones. Example: if you have
ethane (H3CCH3) and you delete the C-C bond, you have two CH3 radicals within
one molecule object ($mol). When you call $mol->separate you get two molecules,
each one with a CH3.

=cut

# splits a molecule into connected fragments
# returns a list of molecules. Does not touch the original copy.
sub separate {
    my ($self) = @_;
    $self = $self->clone;
    $self->{_paint_tab} = {};
    my $color = 0;
    for my $atom ($self->atoms) {
        next if defined $self->{_paint_tab}{$atom->id};
        $self->_paint($atom, $color++);
    }
    my @mols;
    push @mols, $self->new for (1 .. $color);
    for my $atom ($self->atoms) {
        $mols[$self->{_paint_tab}{$atom->id}]->add_atom($atom);
    }
    for my $bond ($self->bonds) {
        $mols[$self->{_paint_tab}{$bond->id}]->add_bond($bond);
    }
    @mols;
}

sub _paint {
    my ($self, $atom, $color) = @_;
    return if $self->{_paint_tab}{$atom->id} eq $color;
    $self->{_paint_tab}{$atom->id} = $color;
    $self->{_paint_tab}{$_->id} = $color for ($atom->bonds);
    for my $neighbor ($atom->neighbors) {
        $self->_paint($neighbor, $color);
    }
}

1;

=back

=head1 VERSION

0.20

=head1 SEE ALSO

L<Chemistry::Atom>, L<Chemistry::Bond>, L<Chemistry::File>,
L<Chemistry::Tutorial>

The PerlMol website L<http://www.perlmol.org/>

=head1 AUTHOR

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

