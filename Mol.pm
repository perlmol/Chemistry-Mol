package Chemistry::Mol;

=head1 NAME

Chemistry::Mol - Molecule object core library

=head1 SYNOPSIS

    use Chemistry::Mol;

    $mol = new Chemistry::Mol(id => "mol_id");
    $mol->add_atom($atom1, $atom2);
    $mol->add_bond($bond);

    print $mol->print;

    $mol2 = Chemistry::Mol::read_mol("file.pdb", "pdb");
    print $mol2->print;

=head1 DESCRIPTION

This package, along with Chemistry::Atom and Chemistry::Bond, includes basic
objects and methods to describe molecules. 

The core methods try not to commit to a particular convention, therefore fields
such as the bond type have no intrinsic meaning. Bonds are defined as a list of
atoms (typically two) with an arbitrary type. Atoms are defined by a symbol and
a Z, and may have 3D coordinates (2D and internal coming soon).

Constructors receive an optional list of named parameters.

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

=head2 Mol attributes

This basic Mol elements should be considered read only! To add or delete atoms
and bonds, use the corresponding methods.

=over 4

=item atoms

An array of the atom objects in the molecule.

=item bonds

An array of bonds.

=item byId

A hash of the atoms and bonds in the molecule, using their id as the key.

=back

=cut


use Chemistry::Atom;
use Chemistry::Bond;
use Carp;
use base qw(Exporter Chemistry::Obj);

$VERSION = '0.10';


@EXPORT = qw();
@EXPORT_OK = qw( read_mol );

%EXPORT_TAGS = (
   all  => [@EXPORT, @EXPORT_OK]
);


use overload '""' => \&stringify;

%FILE_FORMATS = ();
my $N = 0;

=head1 METHODS

=over 4

=item Chemistry::Mol->new(name => value, ...)

Create a new Mol object with the specified attributes. Sensible defaults
are used when possible.

=cut

sub new {
    my $class = shift;
    my $newmol = bless {
	id => $class->nextID,
	byId => {}, 
	atoms => [], 
	bonds => [], 
	name => "",
    }, $class;
    %$newmol = (%$newmol, @_);
    return $newmol;
}

sub nextID {
    "mol".++$N; 
}

=item $mol->add_atom($atom, ...)

Add one or more Atom objects to the molecule.

=cut

sub add_atom {
    my $self = shift;
    my $a;

    for $a (@_){
        push @{$self->{atoms}}, $a;
        $self->{byId}{$a->{id}} = $a;
    }
}


=item $mol->add_bond($bond, ...)

Add one or more Bond objects to the molecule. Automatically calls the add_bond
method for each of the atoms involved.

=cut

sub add_bond {
    my $self = shift;

    for my $b (@_){
        push @{$self->{bonds}}, $b;
	$self->{byId}{$b->{id}} = $b;

        for my $a (@{$b->{atoms}}){
            $a->add_bond($b);
        }
    }
}

=item $mol->print

Convert the molecule to a string representation. 

=cut

sub print {
    my $self = shift;
    my $ret;
    my ($a, $b);
    local $" = ""; #"

    $ret = <<END;
$self->{id}:
    name: $self->{name}
END
    $ret .= <<E;
    atoms:
E
    for $a (@{$self->{atoms}}) { $ret .= $a->print }
    $ret .= <<E;
    bonds:
E
    for $b (@{$self->{bonds}}) { $ret .= $b->print }
    $ret;
}

=item $mol->stringify

Used to overload "", returns the ID of the molecule.

=cut

sub stringify {
    my $self = shift;
    $self->{id};
}

=item read_mol($fname, [$type])

Read a file returning a list of Mol objects, or 0 if there
was a problem. The type of file will be guessed if not
specified.

Note that only registered file readers will be used. Readers may
be registered using register_type(); modules that include readers
(such as Chemistry::File::PDB) usually register them automatically.

This function may be exported.

=cut

sub read_mol($;$) {
    my $fname = shift;
    my $type = shift;

    if ($type) {
	return $FILE_FORMATS{$type}->{read}($fname);
    } else {
	#print "No type specified...\n";
	for $type (keys %FILE_FORMATS) {
	    #print "is file $type?\n";
	    if ($FILE_FORMATS{$type}->{is}($fname)){
		#print "file is $type!\n";
		return $FILE_FORMATS{$type}->{read}($fname);
	    }
	}
    }
    return 0;
}

=item register_type($name, sub_id => \&sub,... )

Register a file type. The identifier $name must be unique.
To register a file type, you need to provide references to 
at least some of the following functions, identified by their 
respective sub_id's.

=over 4

=item is

A reference to a function that receives a filename and returns 1 if the
file is of the specified type.

=item read 

A reference to a function that receives a filename and returns the list
of Mols contained in the file.

=item write 

A reference to a function that receives a filename and a list of
molecules and writes the molecules to the file.

=item parse

A reference to a function that receives a string and returns the list
of Mols contained in the string.

=item print

A reference to a function that receives a list of
molecules and returns a string.

=back

=cut

sub register_type {
    my $type = shift;

    $FILE_FORMATS{$type} = {@_};
}

1;

=head1 SEE ALSO

Chemistry::Atom, Chemistry::Bond, Chemistry::File

=head1 AUTHOR

Ivan Tubert-Brohman <ivan@tubert.org>

=head1 VERSION

$Id$

=cut

