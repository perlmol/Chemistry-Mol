#!/home/ivan/bin/perl -w 

use Data::Dumper;
use blib;
use Chemistry::Mol;
use Chemistry::File ":auto";

print "Formats: ", join (",", Chemistry::Mol->formats), "\n";

my $mol = Chemistry::Mol->new;
my $a1 = Chemistry::Atom->new(symbol=>'C', name => 'carbon');
my $a2 = Chemistry::Atom->new(symbol=>'O', name => 'oxygen');
$mol->add_atom($a1, $a2);
my $b1 = Chemistry::Bond->new(atoms=>[$a1,$a2]);
$mol->add_bond($b1);
my $a3 = $mol->new_atom(symbol=>'Cl', name => 'chlorine');
$mol->new_bond(order=>2, atoms=>[$a1, $a3]);
$mol->name('a molecule');
$mol->attr('mp',333);
$mol->attr('mdl:dim',2);
$a2->attr('am1:charge', -0.23);
$b1->attr('am1:order', 0.987);
print "a mol:'$mol'\n";


use Chemistry::File::MDLMol;
$mol = Chemistry::Mol->read("test.mol");
print "Mass: ", $mol->mass, "\n";
print "Formula: ", $mol->formula, "\n";
print "Formula: ", $mol->formula("%s %D "), "\n";
print "Formula: ", $mol->formula("%s%d{<sub>%d</sub>}"), "\n";
print "Formula: ", $mol->formula("%s%d{_%d}"), "\n";

