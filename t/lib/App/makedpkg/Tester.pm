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

our @EXPORT = (qw(makedpkg write_file path), @cmd);

sub makedpkg(@) {
    $RESULT = test_app('App::makedpkg' => [@_]);
}

sub write_file(@) {
    open my $fh, ">", $_[0];
    print $fh $_[1] . "\n";
    close $fh;
}

# always start in a new, temporary directory
our $DIR;
sub path { $DIR.(@_ ? '/'.$_[0] : ''); }
chdir ($DIR = tempdir);

1;
