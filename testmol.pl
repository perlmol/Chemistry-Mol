#!/home/ivan/bin/perl -w 

use Data::Dumper;
use blib;
use Chemistry::Mol;

my $mol = Chemistry::Mol->new;
my $a1 = Chemistry::Atom->new(symbol=>'C');
my $a2 = Chemistry::Atom->new(symbol=>'O');
$mol->add_atom($a1, $a2);
my $b1 = Chemistry::Bond->new(atoms=>[$a1,$a2]);
$mol->add_bond($b1);
my $a3 = $mol->new_atom(symbol=>'Cl');
$mol->new_bond(order=>2, atoms=>[$a1, $a3]);
$mol->name('a molecule');
$mol->attr('mp',333);
$mol->attr('mdl:dim',2);
$a2->attr('am1:charge', -0.23);
$b1->attr('am1:order', 0.987);
print $mol->print;
print "a mol:'$mol'\n";
#print $mol->attr('mp');
#print Dumper($mol);
