#use Test::More "no_plan";
use Test::More tests => 4;
BEGIN { 
    use_ok('Chemistry::File::Formula');
};

# Constructors
my $mol = Chemistry::Mol->parse("CH4O", format => "formula");
isa_ok($mol, 'Chemistry::Mol', 'parse isa mol');
ok($mol->atoms == 6, "enough atoms");
my $formula = $mol->formula("%s%d{<sub>%d</sub>}");
is($formula, "CH<sub>4</sub>O", "formula format");
