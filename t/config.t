use strict;
use Test::More;
use App::makedpkg;

use lib 't/lib';
use App::makedpkg::Tester;

mkdir path("makedpkg"); # implicit template directory

makedpkg '-n';
ok exit_code;
is error, "error reading config file \n", "error reading config file ";

makedpkg qw(--config notfound.yml -n);
ok exit_code;
is error, "error reading config file notfound.yml\n", "error reading config file notfound.yml";

write_file "malformed.yml", ".";

makedpkg qw(--config malformed.yml -n);
ok exit_code;
is error, "error reading config file malformed.yml\n", "error reading config file malformed.yml";

write_file "ok.yml", "foo: bar";
makedpkg qw(--config ok.yml --verbose -n);
ok !exit_code;
is output, "---\nfoo: bar\nverbose: 1\n";

write_file "makedpkg.yml", "foo: '`pwd`'";
makedpkg qw(--verbose -n);
ok !exit_code;
is output, "---\nfoo: ".path."\nverbose: 1\n", "expanded config";

write_file "makedpkg.yml", "foo:\n  bar: '`pwd`'";
makedpkg qw(--verbose -n);
ok !exit_code;
is output, "---\nfoo:\n  bar: ".path."\nverbose: 1\n", "expanded config deeply";

write_file "makedpkg.yml", "foo: '`rm /dev/null`'";
makedpkg qw(--verbose -n);
ok exit_code;
is error, "`rm /dev/null` died with exit code 1\n";

makedpkg '-t',path("notfound"),'-n';
ok exit_code;
is error, "error reading template directory ".path("notfound")."\n", "error reading template directory";

done_testing;
