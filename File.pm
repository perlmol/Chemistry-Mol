package Chemistry::File;
$VERSION = '0.26';

=head1 NAME

Chemistry::File - Molecule file I/O base class

=head1 SYNOPSIS

    # As a convenient interface for several mol readers:
    use Chemistry::Mol;
    use Chemistry::File qw(PDB MDLMol); # load PDB and MDL modules
    
    # or try to use every file I/O module installed in the system:
    use Chemistry::File ':auto';

    my $mol1 = Chemistry::Mol->read("file.pdb");
    my $mol2 = Chemistry::Mol->read("file.mol");

    # as a base for a mol reader:

    package Chemistry::File::Myfile;
    use base Chemistry::File;
    Chemistry::Mol->register_type("myfile", __PACKAGE__);
    # override the parse_string method
    sub parse_string {
        my ($self, $string, %opts) = shift;
        my $mol_class = $opts{mol_class} || "Chemistry::Mol";
        my $mol = $mol_class->new;
        # ... do some stuff with $string and $mol ...
        return $mol;
    }

=head1 DESCRIPTION

The main use of this module is as a base class for other molecule file I/O
modules (for example, Chemistry::File::PDB). Such modules should extend
the Chemistry::File methods as needed. You only need to care about them
if you are writing a file I/O module.

From the user's point of view, this module can also be used as shorthand
for using several Chemistry::File modules at the same time.

    use Chemistry::File qw(PDB MDLMol);

is exactly equivalent to

    use Chemistry::File::PDB;
    use Chemistry::File::MDLMol;

If you use the :auto keyword, Chemistry::File can try to autodetect and load
all the Chemistry::File::* modules installed in your system.

    use Chemistry::File ':auto';

=head1 STANDARD OPTIONS

All the methods below include a list of options %options at the end of the
parameter list. Each class implementing this interface may have its own
particular options. However, the following options should be recognized by
all classes:

=over

=item mol_class

A class or object with a C<new> method that constructs a molecule. This is 
needed when the user want to specify a molecule subclass different from the
default. When this option is not defined, the module may use Chemistry::Mol 
or whichever class is appropriate for that file format.

=item format

The file format being used, as registered by Chemistry::Mol->register_format.

=back

=head1 METHODS

The methods in this class (or rather, its derived classes) are usually not
called directly. Instead, use Chemistry::Mol->read, write, print, and parse.

=over 4

=cut

use strict;
use Carp;
use FileHandle;
use base qw(Chemistry::Obj);
use warnings;

# This subroutine implements the :auto functionality
sub import {
    my $pack = shift;
    for my $param (@_){
        if ($param eq ':auto') {
            for my $pmfile (map {glob "$_/Chemistry/File/*.pm"} @INC) {
                my ($pm) = $pmfile =~ m|(Chemistry/File/.*\.pm)$|;
                #warn "requiring $pm\n";
                eval { require $pm }; 
                die "Error in Chemistry::File: '$@'\n" if $@;
            }
        } else {
            eval "use ${pack}::$param";
            die "$@" if $@;
        }
    }
}

=item $class->parse_string($s, %options)

Parse a string $s and return one or mole molecule objects. This is an abstract
method, so it should be provided by all derived classes.

=cut

sub parse_string {
    my $class = shift;
    $class = ref $class || $class;
    croak "parse_string() is not implemented for $class";
}


=item $class->write_string($mol, %options)

Convert a molecule to a string. This is an abstract method, so it should be
provided by all derived classes.

=cut

sub write_string {
    my $class = shift;
    $class = ref $class || $class;
    croak "write_string() is not implemented for $class";
}

=item $class->parse_file($file, %options)

Reads the file $file and returns one or more molecules. The default method
slurps the whole file and then calls parse_string, but derived classes may
choose to override it. $file can be either a filehandle or a filename.

=cut

sub parse_file {
    my ($self, $file, %opts) = @_;

    $self->new(file => $file, opts => \%opts)->read;

    #my $s = $self->slurp($file, %opts);
    #$self->parse_string($s, %opts);
}

=item $class->write_file($mol, $file, %options)

Writes a file $file containing the molecule $mol. The default method calls
write_string first and then saves the string to a file, but derived classes
may choose to override it. $file can be either a filehandle or a filename.

=cut

sub write_file {
    my ($self, $mol, $file, %opts) = @_;

    my $s = $self->write_string($mol, %opts);
    $self->snort($file, $s);
}

=item $class->name_is($fname, %options)

Returns true if a filename is of the format corresponding to the class.
It should look at the filename only, because it may be called with
non-existent files. It is used to determine with which format to save a file.
For example, the Chemistry::File::PDB returns true if the file ends in .pdb.

=cut

sub name_is {
    0;
}

=item $class->string_is($s, %options)

Examines the string $s and returns true if it has the format of the class.

=cut

sub string_is {
    0;
}

=item $class->file_is($file, %options)

Examines the file $file and returns true if it has the format of the class.
The default method slurps the whole file and then calls string_is, but derived
classes may choose to override it.

=cut

sub file_is {
    my ($self, $file, %opts) = @_;
    
    my $s = $self->slurp($file, %opts);
    $self->string_is($s, %opts);
}

=item $class->slurp($file %opts)

Reads a file into a scalar. Automatic decompression of gzipped files is
supported if the IO::Zlib module is installed. Files ending in .gz are assumed
to be compressed; otherwise it is possible to force decompression by passing
the gzip => 1 option (or no decompression with gzip => 0).

=cut

# slurp a file into a scalar, with transparent decompression
sub slurp {
    my ($self, $file, %opts) = @_;

    my $fh;
    my $s;
    if (ref $file) {
        $fh = $file;
    } elsif ($opts{gzip} or !defined $opts{gzip} and $file =~ /.gz$/) {
        eval { require IO::Zlib } or croak "IO::Zlib support not installed";
        $fh = IO::Zlib->new($file, 'rb') 
            or croak "Could not open file $file for reading: $!";
        $s = join '',  <$fh>;
    } else {
        $fh = FileHandle->new("<$file") 
            or croak "Could not open file $file for reading: $!";
        $s = do { local $/; <$fh> };
    }
    $fh->close;
    $s;
}

=item $class->snort($file, $s, %opts)

Write a scalar to a file in one step. Automatic gzip compression is supported
if the IO::Zlib module is installed. Files ending in .gz are assumed to be
compressed; otherwise it is possible to force compression by passing the gzip
=> 1 option (or no compression with gzip => 0). Specific compression levels
between 2 (fastest) and 9 (most compressed) may also be used (e.g., gzip => 9).

=cut

sub snort {
    my ($self, $file, $s, %opts) = @_;
    my $fh;
    if (ref $file) {
        $fh = $file;
    } elsif ($opts{gzip} or !defined $opts{gzip} and $file =~ /.gz$/) {
        eval { require IO::Zlib } or croak "IO::Zlib support not installed";
        my $level = $opts{gzip} || 6;
        $level = 6 if $level == 1;
        $fh = IO::Zlib->new($file, "wb$level") 
            or croak "Could not open file $file for compressed writing: $!";
    } else {
        $fh = FileHandle->new(">$file") 
            or croak "Could not open file $file for writing: $!";
    }
    print $fh $s;
    $fh->close or croak "Error closing $file: $!";
}

Chemistry::Obj::accessor(qw(file fh opts));
sub read_header { }
sub read_footer { }

sub open {
    my ($self, $mode) = @_;
    my $fh;
    my $s;
    $mode ||= '<';
    my $file = $self->file;
    if (ref $file eq 'SCALAR') {
        require IO::String;
        $fh = IO::String->new($$file);
    } elsif (ref $file) {
        $fh = $file;
    } elsif ($self->{opts}{gzip} 
        or !defined $self->{opts}{gzip} and $file =~ /.gz$/) 
    {
        eval { require IO::Zlib } or croak "IO::Zlib support not installed";
        $self->{opts}{gzip} ||= 1;
        $mode = $mode eq '>' ? 'w' : 'r';
        $fh = IO::Zlib->new($file, $mode.'b') 
            or croak "Could not open file $file: $!";
        #print "open gzip($file)\n";
    } else {
        $fh = FileHandle->new("$mode$file") 
            or croak "Could not open file $file: $!";
    }
    $self->fh($fh);
    $self;
}

sub slurp_mol {
    my ($self) = @_;
    my $fh = $self->fh;
    if ($self->{opts}{gzip}) {
        join('', <$fh>);
    } else {
        local $/; <$fh>;
    }
}


sub next_mol {
    my ($self) = @_;
    my $s = $self->slurp_mol;
    return unless defined $s and length $s;
    $self->parse_string($s);
}

sub read {
    my ($self) = @_;
    $self->open('<');
    $self->read_header;
    my @mols;
    while (my $mol = $self->next_mol) {
        push @mols, $mol;
    }
    $self->read_footer;
    wantarray ? @mols : @mols ? $mols[0] : undef;
}


1;

=back

=head1 CAVEATS

The :auto feature may not be entirely portable, but it is known to work under
Unix and Windows (either Cygwin or Activestate).

=head1 VERSION

0.26

=head1 SEE ALSO

L<Chemistry::Mol>

The PerlMol website L<http://www.perlmol.org/>

=head1 AUTHOR

Ivan Tubert-Brohman-Brohman <itub@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004 Ivan Tubert-Brohman. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

