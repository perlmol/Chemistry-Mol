use Test::More;
my @files = (glob("*.pm"), glob("*.pod"));
my $n = @files;
plan tests => $n;

eval 'use Test::Pod';
my $no_test_pod = $@;

SKIP: {
    skip("you don't have Test::Pod installed", $n) if $no_test_pod;
    for my $file (@files) {
        pod_file_ok($file, "POD for '$file'");
    }
}
