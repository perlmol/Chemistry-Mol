package Chemistry::File::Formula;
$VERSION = '0.11';

use strict;
use base "Chemistry::File";
use Chemistry::Mol;
use Carp;

=head1 NAME

Chemistry::File::Formula - Molecular formula reader/formatter

=head1 SYNOPSIS

    use Chemistry::File::Formula;

    my $mol = Chemistry::Mol->parse("H2O");
    print $mol->print(format => formula);
    print $mol->print(format => formula, 
        formula_format => "%s%d{<sub>%d</sub>});

=cut

Chemistry::Mol->register_format('formula');

=head1 DESCRIPTION

This module converts a molecule object to a string with the formula. It
registers the 'formula' format with Chemistry::Mol.
Besides its obvious use, it is included in the Chemistry::Mol distribution
because it is a very simple example of a Chemistry::File derived I/O module.

The format can be specified as a printf-like string with the following control
sequences, which are specified with the formula_format parameter to $mol->print
or $mol->write.

=over

=item %s  symbol

=item %D  number of atoms

=item %d  number of atoms, included only when it is greater than one

=item %d{substr}  substr is only included when number of atoms is greater than one

=back

If no format is specified, the default is "%s%d". Examples:

=over

=item %s%D    Like the default, but include explicit indices for all atoms

=item %s%d{<sub>%d</sub>} HTML format

=back

Formulas can also be parsed back into Chemistry::Mol objects, but currently
this only works for simple formulas with the "%s%d" format.

=cut

sub parse_string {
    my ($self, $string, %opts) = @_;
    my $mol_class = $opts{mol_class} || "Chemistry::Mol";
    my $atom_class = $opts{atom_class} || "Chemistry::Atom";
    my $bond_class = $opts{bond_class} || "Chemistry::Bond";

    my $mol = $mol_class->new;
    $string =~ /^(?:([A-Z][a-z]*)(\d*))+$/ or croak("invalid formula $string\n");
    my (%formula) = $string =~ m/([A-Z][a-z]*)(\d*)/g;
    for (values %formula) {
        $_ = 1 unless length; # Add implicit indices
    }
    for my $sym (keys %formula) {
        for (my $i = 0; $i < $formula{$sym}; ++$i) {
            $mol->add_atom($atom_class->new(symbol => $sym));
        }
    }
    return $mol;
}

sub write_string {
    my ($self, $mol, %opts) = @_;
    my $formula = "";
    my $format = $opts{formula_format} || "%s%d"; # default format
    my $fh = $mol->formula_hash;
    for my $sym (sort keys %$fh) {
        my $s = $format;
        my $n = $fh->{$sym};
        $s =~ s/(?<!\\)%s/$sym/g;
        $s =~ s/(?<!\\)%D/$n/g;
        $s =~ s/(?<!\\)%d\{(.*)\}/$n > 1 ? $1 : ''/eg;
        $s =~ s/(?<!\\)%d/$n > 1 ? $n : ''/eg;
        $s =~ s/\\(.)/$1/g;
        $formula .= $s;
    }
    $formula;
}


sub file_is {
    return 0; # no files are identified automatically as having this format
}

1;

=head1 SEE ALSO

L<Chemistry::Mol>, L<Chemistry::File>

=head1 AUTHOR

Ivan Tubert-Brohman <itub@cpan.org>

=cut

