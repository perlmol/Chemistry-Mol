package Chemistry::Bond;

=head1 NAME

Chemistry::Bond

=head1 SYNOPSIS

    use Chemistry::Bond;

    my $bond = new Chemistry::Bond(
	id => "b1", 
	type => '=', 
	atoms => [$a1, $a2]
    );

    print $bond;

=cut


use strict;
use overload '""' => \&stringify;

use vars qw($N);
$N = 0;

=head1 METHODS

=over 4

=item Chemistry::Bond->new(name => value, ...)

Create a new Bond object with the specified attributes. Sensible defaults
are used when possible.

=cut

sub new {
    my $class = shift;
    my $newbond = bless {id => "b".++$N, type => '', atoms => []} , $class;

    %$newbond = (%$newbond, @_);
    return $newbond;
}

=item $bond->length()

Returns the length of the bond, i.e., the distance between the two atom
objects in the bond. Returns zero if the bond does not have exactly two atoms.

=cut

sub length {
    my $self = shift;

    if (@{$self->{atoms}} == 2) {
	my $v = $self->{atoms}[1]{coords} - $self->{atoms}[0]{coords};
	return $v->length;
    } else {
	return 0;
    }
}

sub print {
    my $self = shift;
    my $l = sprintf "%.4g", $self->length;
    return <<EOF;
    <bond id="$self->{id}">
        type = $self->{type}
        atom1 = $self->{atoms}[0]{id}
        atom2 = $self->{atoms}[1]{id}
	length = $l
    </bond>
EOF
}

sub stringify {
    my $self = shift;
    $self->{id};
}


1;

=back

=head1 SEE ALSO

Chemistry::Mol, Chemistry::Atom

=head1 AUTHOR

Ivan Tubert-Brohman <ivan@tubert.org>

=head1 VERSION

$Id$

=cut

