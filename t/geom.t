use Test::More;

#plan 'no_plan';
plan tests => 4;

use Chemistry::File::Dumper;

my $mol = Chemistry::Mol->read("t/mol.pl");
isa_ok( $mol, 'Chemistry::Mol' );

my (@a);

# angle
@a = $mol->atoms(1,2,3);
is( scalar @a, 3, 'three atoms');
is_float( Chemistry::Atom::angle_deg(@a), 110.7, 0.1, "angle" );

# dihedral
@a = $mol->atoms(1,2,3,4);
is_float( Chemistry::Atom::dihedral_deg(@a), -85.6,  0.1, "dihedral" );

sub is_float {
    my ($got, $expected, $tol, $name) = @_;
    ok( abs($got - $expected) < $tol, $name ) 
        or diag "got $got, expected $expected";
}
