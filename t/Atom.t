use strict;
use warnings;

use Test::More "no_plan";
#use Test::More tests => 22;

BEGIN { 
    use_ok('Chemistry::Atom');
};

my ($atom, $atom2);

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





