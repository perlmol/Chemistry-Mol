use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Chemistry::Mol',
    'VERSION_FROM'	=> 'Mol.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        'Math::VectorReal' => 1.0,
        'Test::Simple' => 0,
        'Scalar::Util' => 1.01,
    },
    'PMLIBDIRS'         => ['File'],
);
