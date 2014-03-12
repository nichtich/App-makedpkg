#ABSTRACT: facilityte unit tests
package App::makedpkg::Tester;
use strict;
use parent 'Exporter';
use File::Temp qw(tempdir);
use App::Cmd::Tester;

# shortcuts to App::Cmd::Tester result
our $RESULT;
our @cmd = qw(stdout stderr output error exit_code);
eval "sub $_() { \$RESULT->$_ }" for @cmd;

our @EXPORT = (qw(makedpkg write_file write_yaml path), @cmd);

sub makedpkg(@) {
    $RESULT = test_app('App::makedpkg' => [@_]);
}

sub write_file(@) {
    open my $fh, ">", shift;
    print $fh @_;
    close $fh;
}

sub write_yaml(@) {
    my $file = shift;
    write_file($file, join "\n", "---", @_, "");
}

# always start in a new, temporary directory
our $DIR;
sub path { 
    $DIR.(@_ ? '/'.$_[0] : ''); 
}
sub start_test {
    chdir ($DIR = tempdir);
}

start_test;

1;
