use strict;
use warnings;

use Test::More "no_plan";
#use Test::More tests => 22;

BEGIN { 
    use_ok('Chemistry::Atom');
    use_ok('Chemistry::Mol');
    use_ok('Math::VectorReal');
};

my ($atom, $atom2, $atom3);

# constructor
$atom = Chemistry::Atom->new;
isa_ok( $atom, 'Chemistry::Atom', 'blank atom' );
isa_ok( $atom, 'Chemistry::Obj',  'blank atom' );

# symbol
$atom = Chemistry::Atom->new(symbol => 'C');
is( $atom->symbol, 'C', 'symbol -> symbol' );
is( $atom->Z,       6,  'symol -> Z' );

# Z
$atom->Z(8);
is( $atom->Z,       8,  'Z -> Z' );
is( $atom->symbol, 'O', 'Z -> symbol' );

# mass
ok( abs($atom->mass-16.00)<0.01, 'default mass');
$atom->mass(18.012);
is( $atom->mass, 18.012, 'arbitrary mass' ); 

# aromatic
ok( ! $atom->aromatic, 'aromatic default' );
$atom->aromatic(1);
ok( $atom->aromatic, 'aromatic' );

# default hydrogens
ok( ! $atom->hydrogens,             'hydrogens default' );
ok( ! $atom->total_hydrogens,       'total_hydrogens default' );
ok( ! $atom->implicit_hydrogens,    'implicit_hydrogens default' );

# set hydrogens
$atom->hydrogens(1);
is( $atom->hydrogens,               1,  'hydrogens' );
is( $atom->implicit_hydrogens,      1,  'implicit_hydrogens' );
is( $atom->total_hydrogens,         1,  'total_hydrogens' );

# set implicit_hydrogens
$atom->implicit_hydrogens(2);
is( $atom->hydrogens,               2,  'hydrogens' );
is( $atom->implicit_hydrogens,      2,  'implicit_hydrogens' );
is( $atom->total_hydrogens,         2,  'total_hydrogens' );
is( $atom->explicit_valence,        0,  'explicit_valence' );
is( $atom->valence,                 2,  'valence' );

# sprout_hydrogens
my $mol = Chemistry::Mol->new;
$mol->add_atom($atom);

$atom->sprout_hydrogens;
is( $atom->hydrogens,               0,  'hydrogens' );
is( $atom->implicit_hydrogens,      0,  'implicit_hydrogens' );
is( $atom->total_hydrogens,         2,  'total_hydrogens' );
is( $atom->explicit_valence,        2,  'explicit_valence' );
is( $atom->valence,                 2,  'valence' );

# collapse_hydrogens
$atom->collapse_hydrogens;
is( $atom->hydrogens,               2,  'hydrogens' );
is( $atom->implicit_hydrogens,      2,  'implicit_hydrogens' );
is( $atom->total_hydrogens,         2,  'total_hydrogens' );
is( $atom->explicit_valence,        0,  'explicit_valence' );
is( $atom->valence,                 2,  'valence' );

# coords
$atom2 = Chemistry::Atom->new(coords => [3,0,4]);
is( $atom->distance($atom2),    5,  'distance(coords(arrayref))' );
my $v1 = $atom2->coords;
my $v = vector(0,10,0);
$atom2->coords($v);
is( $atom->distance($atom2),   10,  'distance(coords(vector))' );
$atom2->coords(3,0,0);
is( $atom->distance($atom2),    3,  'distance(coords(list))' );

# x3, y3, z3 accessors
$atom2->coords($v1);
my $x = $atom2->x3;
is($x, 3, 'x3');
my $y = $atom2->y3;
is($y, 0, 'y3');
my $z = $atom2->z3;
is($z, 4, 'z3');

# distance
is( $atom->distance($v1),       5,  'distance(vector)' );

# sprintf
is( $atom->sprintf("%s"),       'O', 'sprintf - %s' );
is( $atom->sprintf("%Z"),       8,   'sprintf - %Z' );
is( $atom2->sprintf("%x,%y,%z"), '3,0,4',   'sprintf - %x,%y,%z' );


