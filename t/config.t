use strict;
use Test::More;
use App::Cmd::Tester;
use App::makedpkg;
use File::Temp qw(tempdir);

sub write_file($$) {
    open my $fh, ">", $_[0];
    print $fh $_[1] . "\n";
    close $fh;
}

chdir (my $tempdir = tempdir);
mkdir "$tempdir/makedpkg"; # implicit template directory

my $res = test_app('App::makedpkg' => ['-n']);
ok $res->exit_code;
is $res->error, "error reading config file \n", "error reading config file ";

$res = test_app('App::makedpkg' => [qw(--config notfound.yml -n)]);
ok $res->exit_code;
is $res->error, "error reading config file notfound.yml\n", "error reading config file notfound.yml";

write_file "malformed.yml", ".";

$res = test_app('App::makedpkg' => [qw(--config malformed.yml -n)]);
ok $res->exit_code;
is $res->error, "error reading config file malformed.yml\n", "error reading config file malformed.yml";

write_file "ok.yml", "foo: bar";
$res = test_app('App::makedpkg' => [qw(--config ok.yml --verbose -n)]);
ok !$res->exit_code;
is $res->output, "---\nfoo: bar\n";

write_file "makedpkg.yml", "foo: '`pwd`'";
$res = test_app('App::makedpkg' => [qw(--verbose -n)]);
ok !$res->exit_code;
is $res->output, "---\nfoo: $tempdir\n", "expanded config";

write_file "makedpkg.yml", "foo:\n  bar: '`pwd`'";
$res = test_app('App::makedpkg' => [qw(--verbose -n)]);
ok !$res->exit_code;
is $res->output, "---\nfoo:\n  bar: $tempdir\n", "expanded config deeply";

write_file "makedpkg.yml", "foo: '`rm /dev/null`'";
$res = test_app('App::makedpkg' => [qw(--verbose -n)]);
ok $res->exit_code;
is $res->error, "`rm /dev/null` died with exit code 1\n";

$res = test_app('App::makedpkg' => ['-t',"$tempdir/notfound",'-n']);
ok $res->exit_code;
is $res->error, "error reading template directory $tempdir/notfound\n", "error reading template directory";

done_testing;
