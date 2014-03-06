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

write_file "makedpkg.yml", "foo: bar";

my @templates = qw(changelog control rules);

my $res = test_app('App::makedpkg' => ['--init','--dry']);
ok !$res->exit_code;
is $res->output, join("\n",map { "created makedpkg/$_" } sort @templates)."\n";
ok( ! -d "$tempdir/makedpkg", "dry init run");

$res = test_app('App::makedpkg' => ['--init']);
ok !$res->exit_code;
is $res->output, join("\n",map { "created makedpkg/$_" } sort @templates)."\n";
ok -d "$tempdir/makedpkg", "init makedpkg templates";
ok(-e "$tempdir/makedpkg/$_", "created $_") foreach @templates;

unlink "$tempdir/makedpkg/rules";
$res = test_app('App::makedpkg' => ['--init']);
ok !$res->exit_code;
like $res->output, qr{kept makedpkg/control}m;
like $res->output, qr{created makedpkg/rules}m;
ok -e "$tempdir/makedpkg/rules", "created rules";

done_testing;
