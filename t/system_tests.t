use strict;
use warnings FATAL => 'all';

$SIG{__DIE__} = sub {
    local $Carp::CarpLevel = 0;
    &Carp::confess;
};

use Test::More;

use File::Find::Rule qw();
use File::Spec qw();
use File::Basename qw();

use TestHelper qw();


sub system_test_base_dir {
    my ($name, $path, $suffix) = File::Basename::fileparse(__FILE__, '.t');

    return File::Spec->join($path, 'SystemTest');
}

sub test_dirs {
    my @a = File::Find::Rule->directory->maxdepth(1)->in(
        system_test_base_dir());
    shift @a;
    return @a;
}

sub source_file {
    my $test_dir = shift;
    return File::Spec->join($test_dir, 'root.gms');
}

sub compiler_expected_result {
    my $test_dir = shift;
    return File::Spec->join($test_dir, 'compiler-output');
}

sub label {
    my $test_dir = shift;

    my ($name, $path, $suffix) = File::Basename::fileparse($test_dir);

    return $name;
}


sub should_update_directory {
    return $ENV{UPDATE_TEST_DATA} || undef;
}

for my $test_dir (test_dirs()) {
    subtest $test_dir => sub {
        my $output_directory = File::Temp::tempdir(CLEANUP => 1);
        TestHelper::compile(source_file($test_dir), $output_directory,
            label($test_dir));

        TestHelper::diff_directories(compiler_expected_result($test_dir),
            $output_directory, label($test_dir));

        if (defined(should_update_directory())) {
            TestHelper::update_directory(compiler_expected_result($test_dir),
                $output_directory);
        }
    };
}

done_testing();
