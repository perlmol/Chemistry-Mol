#use Test::More "no_plan";
use Test::More tests => 22;
BEGIN { 
    use_ok('Chemistry::Mol');
    use_ok('Math::VectorReal');    
};

# Constructors
my $mol = Chemistry::Mol->new;
isa_ok($mol, 'Chemistry::Mol', '$mol');
isa_ok($mol, 'Chemistry::Obj', '$mol');
my $atom = Chemistry::Atom->new(Z => 6, coords => [0, 0, 3], name => "carbon");
isa_ok($atom, 'Chemistry::Atom', '$atom');
isa_ok($atom, 'Chemistry::Obj', '$atom');
my $atom2 = Chemistry::Atom->new(Z => 8, coords => [4, 0, 0], id => 'xyz');
my $bond = Chemistry::Bond->new(atoms => [$atom, $atom2], type => '=');
isa_ok($bond, 'Chemistry::Bond', '$bond');
isa_ok($bond, 'Chemistry::Obj', '$bond');

# Mol methods
$mol->add_atom($atom, $atom2);
is(scalar $mol->atoms, 2, '$mol->atoms');
ok($mol->atoms(1) eq $atom, '$mol->atoms(1) eq $atom');
ok($mol->by_id('xyz') eq $atom2, '$mol->by_id');
ok($mol->atoms_by_name('carbon') eq $atom, '$mol->atoms_by_name');
$mol->add_bond($bond);
is(scalar $mol->bonds, 1, '$mol->bonds');
ok($mol->bonds(1) eq $bond, '$mol->bonds(1) eq $bond');
my $atom3;
ok($atom3 = $mol->new_atom(symbol => "N"), '$mol->new_atom');

# Atom methods
is($atom->distance($atom2), 5, '$atom->distance');
is($atom->symbol, "C", '$atom->symbol');
$atom->attr("color", "brown");
is($atom->attr("color"), "brown", '$atom->attr');
my $v = vector(3,0,4);
$atom3->coords($v);
my $v2 = $atom3->coords;
is($v->length, 5, 'atom->coords(vector)');
$atom3->coords([3,0,4]);
$v2 = $atom3->coords;
is($v->length, 5, 'atom->coords(array)');
$atom3->coords(3,0,4);
$v2 = $atom3->coords;
is($v->length, 5, 'atom->coords(list)');

# Bond methods
is($bond->length, 5, '$bond->length');
