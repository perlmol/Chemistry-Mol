use strict;
use warnings;

use Chemistry::Mol;
use Test::More tests => 12;

my $mol = Chemistry::Mol->new;

my $A = $mol->new_atom(symbol => 'C');
my $B = $mol->new_atom(symbol => 'C');

my $A1 = $mol->new_atom(symbol => 'C');
my $A2 = $mol->new_atom(symbol => 'C');
my $B1 = $mol->new_atom(symbol => 'C');
my $B2 = $mol->new_atom(symbol => 'C');

$mol->new_bond(atoms => [$A, $A1]);
$mol->new_bond(atoms => [$A, $A2]);
$mol->new_bond(atoms => [$B, $B1]);
$mol->new_bond(atoms => [$B, $B2]);

my $bond = $mol->new_bond(atoms => [$A, $B],
                          cistrans => [$A1, $B1, 'cis'],
                          type => '=');

is ( $bond->cistrans( $A1, $B1 ), 'cis' );
is ( $bond->cistrans( $A1, $B2 ), 'trans' );
is ( $bond->cistrans( $A2, $B1 ), 'trans' );
is ( $bond->cistrans( $A2, $B2 ), 'cis' );

$bond->cistrans( $A1, $B2, 'trans' );

is ( $bond->cistrans( $A1, $B1 ), 'cis' );
is ( $bond->cistrans( $A1, $B2 ), 'trans' );
is ( $bond->cistrans( $A2, $B1 ), 'trans' );
is ( $bond->cistrans( $A2, $B2 ), 'cis' );

$bond->cistrans( $A1, $B2, undef );

$A1->coords( -1,  0.5, 0 );
$A2->coords( -1, -0.5, 0 );
$B1->coords(  1,  0.5, 0 );
$B2->coords(  1, -0.5, 0 );

$A->coords( -0.5, 0, 0 );
$B->coords(  0.5, 0, 0 );

is ( $bond->cistrans( $A1, $B1 ), 'cis' );
is ( $bond->cistrans( $A1, $B2 ), 'trans' );
is ( $bond->cistrans( $A2, $B1 ), 'trans' );
is ( $bond->cistrans( $A2, $B2 ), 'cis' );
