use strict;
use warnings;

use Test::More;

BEGIN { 
    plan 'no_plan';
    use_ok('Chemistry::File');
}

#plan tests => 6;

# simple constructor test
my $f = Chemistry::File->new;
isa_ok($f, "Chemistry::File");

require Chemistry::File::Dumper;

# file reader test
my $fname = 't/mol.pl';
my $file = Chemistry::File::Dumper->new(file => $fname);
isa_ok($file, "Chemistry::File::Dumper");
my $mol = $file->read(format => 'dumper');

isa_ok($mol, "Chemistry::Mol", 'read file');
is(scalar $mol->atoms, 8, "atoms");


# string reader test
open F, "<$fname" or die;
my $s = do {local $/; <F>};
$file = Chemistry::File::Dumper->new(file => \$s);
$mol  = $file->read;

isa_ok($mol, "Chemistry::Mol", 'read string');
is(scalar $mol->atoms, 8, "atoms");


