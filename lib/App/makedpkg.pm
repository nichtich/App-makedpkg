package App::makedpkg;
#ABSTRACT: Build Debian Packages based on templates
#VERSION
use strict;
use v5.10.0;

use base qw(App::Cmd::Simple);
 
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Copy ();
use Text::Template qw(fill_in_file);
use YAML::Tiny qw(Dump);
use Config::Any;
use File::ShareDir qw(dist_dir);

our $dist_dir = dist_dir('App-makedpkg');

sub opt_spec {
    return (
        [ "config|c=s", "configuration file" ],
        [ "verbose|v", "verbose output" ],
        [ "templates|t=s", "template directory" ],
        [ "dry|n", "don't build, just show" ],
        [ "prepare|p", "prepare build" ],
        [ "force|f", "use the force, Luke!" ],
        [ "init", "initialize template directory makedpkg/" ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
      
    $self->{config} = $self->read_config($opt->config);

    if (!defined $opt->templates) {
        if (-d 'makedpkg') {
            $opt->{templates} = 'makedpkg';
        } else {
            $opt->{templates} = $dist_dir;
        }
    }

    unless ( -d $opt->templates ) {
        die "error reading template directory ".$opt->templates."\n";
    }
}

sub read_config {
    my ($self, $file, $config) = @_;

    if (defined $file) {
        $config = Config::Any->load_files({ files => [$file], use_ext => 1, flatten_to_hash => 1 });
    } else {
        $config = Config::Any->load_stems({ stems => ['makedpkg'], use_ext => 1, flatten_to_hash => 1 });
    }

    if (keys %$config) {
        ($file) = keys %$config;
        ($config) = values %$config;
    } else {
        $config = undef;
    }

    if ( ref ($config // '') ne 'HASH' ) {
        die "error reading config file $file\n";
    }

    return $config;
}

sub expand_command {
    my ($cmd, $out) = @_;

#    use IPC::Open3;
#    use File::Spec;
#    use Symbol qw(gensym);
#    open(NULL, ">", File::Spec->devnull);
#    my $pid = open3(gensym, \*PH, ">&NULL", $cmd);
#    while( <PH> ) { $out .= $_ }
#    waitpid($pid, 0);

    $out = `$cmd`;
    die "`$cmd` died with exit code ".($?>>8)."\n" if $?;
    chomp $out;

    return $out;
}

sub expand_config {
    my $h = $_[0];
    return if (ref $h || "") ne 'HASH';
    foreach my $key (keys %$h) {
        my $v = $h->{$key};
        if ( !ref $v and $v =~ /^`(.+)`$/ ) {
            $h->{$key} = expand_command($1);
        } else {
            expand_config($v);
        }
    }
}

sub list_dir {
    my ($dir) = @_;
    opendir(my $dh, $dir) or die "failed to open $dir: $!\n";
    my @files = grep { /^[^.]+/ } readdir($dh);
    closedir $dh;
    return \@files;
}

sub execute {
    my ($self, $opt, $args) = @_;

    expand_config($self->{config});
    $self->{config}->{verbose} ||= $opt->verbose ? 1 : 0;

    my $template_dir = $opt->templates;

    if ($opt->verbose) {
        $self->_dump( $self->{config} );
        # say "templates in $template_dir\n";
    }

    if ($opt->init) {
        return $self->init($template_dir, $opt);
    }

    my $template_files = list_dir($template_dir);

    my $conf = $self->{config};
    $conf->{build} //= { };
    $conf->{build}{directory} //= 'debuild';

    # TODO: print build directory if verbose

    my $build_dir = $conf->{build}{directory};

    unless ($opt->dry) {
        remove_tree($build_dir);
        make_path("$build_dir/source/debian");
    }

    unless ($opt->dry) {
        foreach my $template (@$template_files) {
            $template = $opt->templates.'/'.$template;
            next unless -f $template;

            my $filename = "$build_dir/debian/".basename($template);

            open my $fh, ">", $filename;
            print $fh fill_in_file($template, HASH => $conf);
            close $fh;

            say $filename if $opt->verbose;
        }

        # TODO: dynamically build 'install' file

        foreach (@{ $conf->{build}{before} || [ ] }) {
            `$_`;
            die "failed to run $_\n" if $?;
        }

        # TODO: reuse 'install' config
        foreach (@{ $conf->{build}{copy} || [ ] }) {
            `cp -r $_ $build_dir/$_`;
            die "failed to copy $_\n" if $?;
        }

        unless ($opt->prepare) { 
            exec "cd debuild/source && debuild ".($conf->{build}{options} || '');
        }
    }
}

sub init {
    my ($self, $template_dir, $opt) = @_;

    $template_dir = 'makedpkg' if $template_dir eq $dist_dir;
    make_path($template_dir) unless $opt->dry;

    my $templates = list_dir($dist_dir);
    foreach my $file (sort @$templates) {
        if (-e "$template_dir/$file" and !$opt->force) {
            say "kept $template_dir/$file";
        } else {
            say "created $template_dir/$file";
            unless ($opt->dry) {
                File::Copy::copy("$dist_dir/$file", "$template_dir/$file");
            }
        }
    }

    return;
}

sub _dump {
    my ($self, $data) = @_;
    # Config::Any requires any of 'YAML::XS', 'YAML::Syck', or 'YAML'
    for my $pkg (qw(YAML::XS YAML::Syck YAML)) {
        eval "require $pkg";
        unless ( $@ ) { 
            eval "print ${pkg}::Dump(\$data);";
            return; 
        }
    }
}

1;

=head1 DESCRIPTION

See the command line client L<makedpkg> for more documentation.

=head1 SEE ALSO

Several CPAN modules exist to create Debian packages for CPAN modules, e.g.
L<Debian::Perl>.

=encoding utf8
