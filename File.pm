package Chemistry::File;
$VERSION = '0.10';

=head1 NAME

Chemistry::File

=head1 SYNOPSIS

    # As a convenient interface for several mol readers:
    use Chemistry::Mol;
    use Chemistry::File qw(PDB MDLMol);

    my $mol1 = Chemistry::Mol->read("file.pdb");
    my $mol2 = Chemistry::Mol->read("file.mol");

    # as a base for a mol reader:

    package Chemistry::File::Myfile;
    use base Chemistry::File;
    Chemistry::Mol->register_type("myfile", __PACKAGE__);
    sub parse {
        my $self = shift;
        my $string = shift;
        my $mol = Chemistry::Mol->new;
        $mol->attr('string', $string);
        $mol;
    }

=head1 DESCRIPTION

This is a convenience module to use several Chemistry::File modules
at the same time.

    use Chemistry::File qw(PDB MDLMol);

is exactly equivalent to

    use Chemistry::File::PDB;
    use Chemistry::File::MDLMol;

=cut

use strict;
use Carp;

sub import {
    my $pack = shift;
    if(@_) {
        for (@_){
            if ($_ eq ':auto') {
                my ($dir) = $INC{"Chemistry/File.pm"} =~ m|^.*/|g;
                for my $pm (glob "$dir/File/*.pm") {
                    #my ($pm) = $pmfile =~ m|Chemistry/File/.*\.pm|g;
                    require $pm;
                }
            } else {
                eval "use ${pack}::$_";
                die "$@" if $@;
            }
        }
    } 
}

sub parse_string {
    my $class = shift;
    $class = ref $class || $class;
    croak "parse() is not implemented for $class";
}


sub write_string {
    my $class = shift;
    $class = ref $class || $class;
    croak "writestring() is not implemented for $class";
}

sub parse_file {
    my $self = shift;
    my $fname = shift;
    my %opts = @_;
    my $s;
    
    open F, $fname or croak "Could not open file $fname for reading";
    {local undef $/; $s = <F>;}
    close F;
    $self->parse_string($s, %opts);
}

sub write_file {
    my $self = shift;
    my $mol = shift;
    my $fname = shift;
    my %opts = @_;

    my $s = $self->write_string($mol, %opts);
    open F, ">$fname" or croak "Could not open file $fname for writing";
    print F $s;
    close F;
}

sub name_is {
    1;
}

sub string_is {
    0;
}

sub file_is {
    my $self = shift;
    my $fname = shift;
    my %opts = @_;
    my $s;
    
    open F, $fname or croak "Could not open file $fname for reading";
    {local undef $/; $s = <F>;}
    close F;
    $self->string_is($s, %opts);
}

1;

=head1 SEE ALSO

Chemistry::Mol

=head1 AUTHOR

Ivan Tubert-Brohman <itub@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

