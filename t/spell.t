use Test::More;
use Test::Spelling;
add_stopwords(<DATA>);
my @files = (glob("*.pm"), glob("*.pod"), glob("*/*.pm"));
all_pod_files_spelling_ok(@files);

__DATA__
API
ActiveState
BrF
BrH
Brohman
CCH
Gregersen
IUPAC
Khrapov
MDL
MacroMol
Macromolecules
Maksim
Mol
PDB
PerlMol
SDF
Tubert
YAML
asciibetical
attr
autodetect
backwards
coords
dihedral
fh
gz
indices
macromolecules
molfiles
mols
namespace
ok
pdb
postprocessing
pre
rxnfiles
aromaticity
CH
IDs
CH
Chem
HTML
Soc
hydrogens
multi
macromolecule
filename
