package Chemistry::File::Dumper;
$VERSION = '0.25';

require 5.006;
use strict;
use warnings;
use base "Chemistry::File";
use Chemistry::Mol; # should I use it?
use Data::Dumper;
use Carp;

=head1 NAME

Chemistry::File::Dumper

=head1 SYNOPSIS

    use Chemistry::File::Dumper;

    my $mol = Chemistry::Mol->read("mol.pl");
    print $mol->print(format => dumper);
    $mol->write("mol.pl", format => "dumper");

=cut



=head1 DESCRIPTION

This module hooks the Data::Dumper Perl core module to the Chemistry::File
API, allowing you to dump and undump Chemistry::Mol objects easily.
This module automatically registers the "dumper" format with Chemistry::Mol.

For purpuses of automatic file type guessing, this module assumes that
dumped files end in C<.pl>.

This module is useful mainly for debugging purposes, as it dumps I<all> the 
information available in an object, in a reproducible way (so you can use
it to compare molecule objects). However, it wouldn't be a good idea to use it
to read untrusted files, because they may contain arbitrary Perl code.

=cut

Chemistry::Mol->register_format(dumper => __PACKAGE__);

=head1 OPTIONS

The following options can be used when writing a molecule either as
a file or as a string.

=over 4

=item dumper_indent

Value to give to Data::Dumper::Indent. Default is 1.

=item dumper_purity

Value to give to Data::Dumper::Purity. Default is 1.

=back

There are no special options for reading.

=cut

sub write_string {
    my ($self, $mol, %opts) = @_;
    my $d = Data::Dumper->new([$mol],['$mol']);
    $d  ->Sortkeys(1)
        ->Indent(exists $opts{dumper_indent} ? $opts{dumper_indent} : 1)
        ->Purity(exists $opts{dumper_purity} ? $opts{dumper_purity} : 1)
        ->Dump;
}

sub parse_string {
    my ($self, $s, %opts) = @_;
    my $mol;
    eval $s;
    croak "$@" if $@;
    $mol->_weaken;
    $mol;
}

sub name_is {
    my ($self, $name, %opts) = @_;
    $name =~ /\.pl$/i;
}

sub string_is {
    my ($self, $s, %opts) = @_;
    $s =~ /^\$mol/;
}

1;

=head1 VERSION

0.25

=head1 SEE ALSO

L<Chemistry::Mol>, L<Chemistry::File>, L<Data::Dumper>

=head1 AUTHOR

Ivan Tubert-Brohman <itub@cpan.org>

=cut

