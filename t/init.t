use strict;
use Test::More;
use App::makedpkg;

use lib 't/lib';
use App::makedpkg::Tester;

write_yaml "makedpkg.yml", "foo: bar";

my @templates = qw(changelog control rules);

makedpkg '--init', '--dry';
ok !exit_code;
is output, join("\n",map { "created makedpkg/$_" } sort @templates)."\n";
ok( ! -d path('makedpkg'), "dry init run");

makedpkg '--init';
ok !exit_code;
is output, join("\n",map { "created makedpkg/$_" } sort @templates)."\n";
ok -d path("makedpkg"), "init makedpkg templates";
ok(-e path("makedpkg/$_"), "created $_") foreach @templates;

unlink path("makedpkg/rules");
makedpkg '--init';
ok !exit_code;
like output, qr{kept makedpkg/control}m;
like output, qr{created makedpkg/rules}m;
ok -e path("makedpkg/rules"), "created rules";

=cut
# prepare build
write_yaml "makedpkg.yml", "foo: bar";
system("cat makedpkg.yml");
makedpkg '-v','-p';
ok exit_code, 'prepared build';
note stdout;
note stderr;
#note error;

system("find ".path);
=cut

done_testing;
