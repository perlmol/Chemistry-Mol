package Chemistry::Mol;
$VERSION = '0.07';

=head1 NAME

Chemistry::Mol - Molecule object toolkit

=head1 SYNOPSIS

    use Chemistry::Mol;

    $mol = new Chemistry::Mol(id => "mol_id");
    $mol->add_atom($atom1, $atom2);
    $mol->add_bond($bond);

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

use strict;
use Chemistry::Atom;
use Chemistry::Bond;
use Carp;
use base qw(Exporter Chemistry::Obj);


our @EXPORT = qw();
our @EXPORT_OK = qw( read_mol );

our %EXPORT_TAGS = (
   all  => [@EXPORT, @EXPORT_OK]
);

our %FILE_FORMATS = ();
my $N = 0;

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
    }, $class;
    $self->$_($args{$_}) for (keys %args);
    return $self;
}

sub nextID {
    "mol".++$N; 
}

=item $mol->add_atom($atom, ...)

Add one or more Atom objects to the molecule. Returns the last atom added.

=cut

sub add_atom {
    my $self = shift;
    for my $a (@_){
        push @{$self->{atoms}}, $a;
        $self->{byId}{$a->{id}} = $a;
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


=item $mol->add_bond($bond, ...)

Add one or more Bond objects to the molecule. Returns the last bond added.

=cut

sub add_bond {
    my $self = shift;
    for my $b (@_){
        push @{$self->{bonds}}, $b;
	$self->{byId}{$b->{id}} = $b;
    }
    $_[-1];
}

=item $mol->new_bond(name => value, ...)

Shorthand for $mol->add_bond(Chemistry::Bond->new(name => value, ...));
It has the disadvantage that it doesn't let you create a subclass of 
Chemistry::Atom.

=cut

sub new_bond {
    my $self = shift;
    $self->add_bond(Chemistry::Bond->new(@_));
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
    my @ret = grep {$_->name =~ $re} $self->atoms;
    wantarray ? @ret : $ret[0];
}

=for comment
sub select_atoms {
    my $self = shift;
    my %opts = @_;
    my @a = $self->atoms;
    for my $opt (keys %opts) {
        my $re = qr/^$opts{$opt}$/;
        @a = grep {$_->$opt =~ $re} @a;
    }
    @a;
}

=cut

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
    $ret .= "    attr:\n";
    $ret .= $self->print_attr(2);
    $ret .= "    atoms:\n";
    for $a (@{$self->{atoms}}) { $ret .= $a->print(2) }
    $ret .= "    bonds:\n";
    for $b (@{$self->{bonds}}) { $ret .= $b->print(2) }
    $ret;
}

=item read_mol($fname, [$type])

Read a file returning a list of Mol objects, or undef if there
was a problem. The type of file will be guessed if not
specified.

Note that only registered file readers will be used. Readers may
be registered using register_type(); modules that include readers
(such as Chemistry::File::PDB) usually register them automatically.

This function may be exported.

=cut

sub read_mol {
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
    undef;
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

=back

=head1 SEE ALSO

L<Chemistry::Atom>, L<Chemistry::Bond>, L<Chemistry::File>

=head1 AUTHOR

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

