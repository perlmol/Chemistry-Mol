use Test::More;

#plan 'no_plan';
plan tests => 8;

use Chemistry::File::Dumper;
my $dead_atoms = 0;
my $dead_bonds = 0;
my $dead_mols = 0;

{
    my $mol = Chemistry::Mol->read("t/mol.pl");
    isa_ok( $mol, 'Chemistry::Mol' );
    is( scalar $mol->atoms, 8,   'atoms before');
    $mol->atoms(2)->delete;
    is( $dead_atoms,    1,  "delete one atom - atoms" );
    is( $dead_bonds,    4,  "delete one atom - bonds" );
    is( $dead_mols,     0,  "delete one atom - mols" );
}

is( $dead_atoms,    8,  "out of scope - atoms" );
is( $dead_bonds,    7,  "out of scope - bonds" );
is( $dead_mols,     1,  "out of scope - mols" );

sub Chemistry::Mol::DESTROY { $dead_mols++ }
sub Chemistry::Atom::DESTROY { $dead_atoms++ }
sub Chemistry::Bond::DESTROY { $dead_bonds++ }

