use Test::More;

#plan 'no_plan';
plan tests => 8;

use Chemistry::File::Dumper;

my $mol = Chemistry::Mol->read("t/mol.pl");
isa_ok( $mol, 'Chemistry::Mol' );
is( scalar $mol->atoms, 8,   'atoms before');
is( scalar $mol->bonds, 7,   'bonds before');

$mol->bonds(6)->delete;
is( scalar $mol->bonds, 6,   'delete bond');

$mol->delete_atom($mol->atoms(1));
is( scalar $mol->bonds, 6,   'delete atom obj - bonds');
is( scalar $mol->atoms, 7,   'delete atom obj - atoms');

$mol->delete_atom(1);
is( scalar $mol->bonds, 3,   'delete atom index - bonds');
is( scalar $mol->atoms, 6,   'delete atom index - atoms');
