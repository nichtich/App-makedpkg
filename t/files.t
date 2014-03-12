use strict;
use Test::More;
use App::makedpkg;

use lib 't/lib';
use App::makedpkg::Tester;
use File::Path qw(make_path);

sub output_no_config {
    output =~ /^---.+---\n(.*)/ms ? $1 : output;
}

write_yaml "makedpkg.yml", <<'YAML';
name: myapp
author: alice <alice@example.org>
build:
    before:
        - pwd
    files:
        copy:
            "index.html": "srv/myapp"
            "lib/*": "srv/myapp/lib"
        to: srv/myapp/more
        from:
            - files/demo.html
            - some/docs
YAML

# create templates directory
makedpkg '--init', '--verbose';
ok !exit_code;

# create source files
make_path('lib');
write_file 'lib/foo', 'bar';
write_file 'index.html', 'Hello!';
make_path('some/docs');
write_file 'some/docs/readme.txt', '...';
make_path('files');
write_file 'files/demo.html', 'Hi!';

# prepare debuild directory
makedpkg '--prepare', '--verbose';

ok !exit_code;
is output_no_config, <<OUTPUT;
building into debuild
debuild/source/debian/changelog
debuild/source/debian/control
debuild/source/debian/rules
before: pwd
debuild/source/debian/install
OUTPUT

is `find debuild | sort`, <<DEBUILD, 'files copied';
debuild
debuild/files
debuild/files/demo.html
debuild/index.html
debuild/lib
debuild/lib/foo
debuild/some
debuild/some/docs
debuild/some/docs/readme.txt
debuild/source
debuild/source/debian
debuild/source/debian/changelog
debuild/source/debian/control
debuild/source/debian/install
debuild/source/debian/rules
DEBUILD

my $install = `cat debuild/source/debian/install`;
$install =~ s/\n$//g;
is "$install\n", <<INSTALL, 'install file';
index.html srv/myapp
lib/* srv/myapp/lib
files/demo.html srv/myapp/more/files
some/docs srv/myapp/more/some
INSTALL

done_testing;

