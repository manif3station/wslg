use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';
use WSLg::Setup;

sub write_file {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content or die "Unable to write content to $path: $!";
    close $fh or die "Unable to close $path: $!";
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{# comment\nID=ubuntu\nVERSION_ID="24.04"\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my @commands;
    my @files;
    my @ops;
    my $setup = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
        runner            => sub { push @commands, [@_]; push @ops, 'run:' . join( q{ }, @_ ); return 0; },
        installer         => sub { push @files, [@_]; push @ops, 'install:' . $_[0]; return 1; },
    );

    my $result = $setup->execute_setup;
    ok( $result->{applied}, 'default setup applies changes' );
    is( $result->{ubuntu_version}, '24.04', 'setup detects Ubuntu version from os-release' );
    like( $result->{service_content}, qr/runtime-dir\/wayland-0\.lock/, '24.04 service includes runtime-dir permissions fix' );
    is( $result->{override_path}, '/etc/systemd/user/org.gnome.Shell@wayland.service.d/override.conf', '24.04 uses the org.gnome.Shell override path' );
    is( scalar @commands, 6, 'setup runs the expected command count when snap-store is enabled' );
    is_deeply(
        $commands[2],
        [ 'sudo', 'snap', 'install', 'snap-store' ],
        'setup includes snap-store install by default'
    );
    is( $ops[5], 'install:/etc/systemd/system/wslg-fix.service', 'setup writes the service file before the final enable step' );
    is( $ops[6], 'install:/etc/systemd/user/org.gnome.Shell@wayland.service.d/override.conf', 'setup writes the override before the final enable step' );
    is( $ops[7], 'run:sudo systemctl enable wslg-fix.service', 'setup enables the service after both files are written' );
    is( scalar @files, 2, 'setup installs the service unit and override file' );
    is( $files[0][0], '/etc/systemd/system/wslg-fix.service', 'service file is installed at the expected path' );
    like( $result->{start_command}, qr/^DESKTOP_SESSION=ubuntu/m, 'setup returns the GNOME start command' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="20.04"\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my @commands;
    my @files;
    my $setup = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
        runner            => sub { push @commands, [@_]; return 0; },
        installer         => sub { push @files, [@_]; return 1; },
    );

    my $result = $setup->execute_setup( '--dry-run', '--skip-snap-store' );
    ok( !$result->{applied}, 'dry run does not apply changes' );
    ok( $result->{dry_run}, 'dry run flag is set in the result' );
    ok( $result->{skip_snap_store}, 'skip-snap-store flag is set in the result' );
    is( scalar @commands, 0, 'dry run does not execute shell commands' );
    is( scalar @files, 0, 'dry run does not install files' );
    like( $result->{commands}[2], qr/acpi-support-/, '20.04 plan keeps the acpi-support exclusion' );
    is( $result->{override_path}, '/etc/systemd/user/gnome-shell-wayland.service.d/override.conf', '20.04 uses the older override path' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=debian\nVERSION_ID="12"\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my $setup = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
    );

    my $ok = eval { $setup->execute_setup('--dry-run'); 1 };
    ok( !$ok, 'non-Ubuntu distros are rejected' );
    like( $@, qr/supports Ubuntu only/, 'rejection explains the Ubuntu-only constraint' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="22.04"\n} );
    write_file( $proc_ver,   "plain linux kernel string\n" );

    my $setup = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
    );

    my $ok = eval { $setup->execute_setup('--dry-run'); 1 };
    ok( !$ok, 'non-WSL hosts are rejected' );
    like( $@, qr/must run inside WSL/, 'rejection explains the WSL requirement' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="24.10"\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my $setup = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
    );

    my $ok = eval { $setup->execute_setup('--dry-run'); 1 };
    ok( !$ok, 'unsupported Ubuntu versions are rejected' );
    like( $@, qr/Unsupported Ubuntu version: 24\.10/, 'unsupported version error is explicit' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my $setup = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
    );

    my $ok = eval { $setup->execute_setup('--dry-run'); 1 };
    ok( !$ok, 'missing Ubuntu version metadata is rejected' );
    like( $@, qr/Unable to determine Ubuntu version/, 'missing VERSION_ID error is explicit' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="22.04"\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my $setup = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
    );

    my $ok = eval { $setup->execute_setup('--unknown'); 1 };
    ok( !$ok, 'unknown options are rejected' );
    like( $@, qr/Unsupported option: --unknown/, 'unknown option error is explicit' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="22.04"\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my $setup = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
    );

    my $ok = eval { $setup->execute_setup('--ubuntu-version'); 1 };
    ok( !$ok, 'missing ubuntu-version values are rejected' );
    like( $@, qr/--ubuntu-version requires a value/, 'missing ubuntu-version value error is explicit' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="22.04"\n} );
    write_file( $proc_ver,   "plain linux kernel string\n" );

    my $stdout = q{};
    my $stderr = q{};
    open my $out, '>', \$stdout or die $!;
    open my $err, '>', \$stderr or die $!;

    my $exit = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
        stdout_fh         => $out,
        stderr_fh         => $err,
    )->main_setup('--dry-run');

    is( $exit, 2, 'main_setup returns exit code 2 on failure' );
    like( $stderr, qr/must run inside WSL/, 'main_setup writes the error to stderr' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="22.04"\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my $stdout = q{};
    open my $out, '>', \$stdout or die $!;

    my $exit = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
        stdout_fh         => $out,
    )->main_setup('--dry-run', '--ubuntu-version', '22.04');

    is( $exit, 0, 'main_setup returns zero on success' );
    like( $stdout, qr/^WSLg setup summary$/m, 'main_setup prints a human-readable setup heading' );
    like( $stdout, qr/^Ubuntu version: 22\.04$/m, 'main_setup prints the Ubuntu version in readable text' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="24.04"\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my @commands;
    my $setup = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
        runner            => sub { push @commands, [@_]; return 0; },
    );

    my $result = $setup->execute_desktop('--dry-run');
    is( $result->{mode}, 'desktop', 'desktop mode reports its mode' );
    ok( !$result->{applied}, 'desktop dry run does not execute the command' );
    is( scalar @commands, 0, 'desktop dry run does not run shell commands' );
    like( $result->{command}, qr/gnome-session\s*\z/s, 'desktop returns the GNOME session command' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="22.04"\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my @commands;
    my $setup = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
        runner            => sub { push @commands, [@_]; return 0; },
    );

    my $result = $setup->execute_desktop;
    ok( $result->{applied}, 'desktop execution applies changes by default' );
    is( scalar @commands, 1, 'desktop execution runs one shell command' );
    is( $commands[0][0], '/bin/sh', 'desktop uses /bin/sh to start GNOME' );
    is( $commands[0][1], '-lc', 'desktop uses shell -lc mode' );
    like( $commands[0][2], qr/XDG_SESSION_TYPE=wayland/, 'desktop command includes the Wayland environment' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="22.04"\n} );
    write_file( $proc_ver,   "plain linux kernel string\n" );

    my $stdout = q{};
    open my $out, '>', \$stdout or die $!;

    my $setup = WSLg::Setup->new(
        env             => { WSL_DISTRO_NAME => 'Ubuntu-22.04' },
        os_release_path => $os_release,
        proc_version_path => $proc_ver,
        stdout_fh       => $out,
    );

    my $exit = $setup->main_setup('--dry-run');
    is( $exit, 0, 'instance main_setup succeeds through the env-based WSL detection path' );
    like( $stdout, qr/^WSLg setup summary$/m, 'instance main_setup prints the readable setup heading' );
    like( $stdout, qr/^Dry run: yes$/m, 'instance main_setup prints the dry-run state' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="22.04"\n} );
    write_file( $proc_ver,   "Linux version 6.1.0-microsoft-standard-WSL2\n" );

    my $stdout = q{};
    open my $out, '>', \$stdout or die $!;

    my $exit = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
        stdout_fh         => $out,
        runner            => sub { return 0; },
    )->main_desktop('--dry-run');

    is( $exit, 0, 'main_desktop returns zero on success' );
    like( $stdout, qr/^WSLg desktop summary$/m, 'main_desktop prints a human-readable desktop heading' );
    like( $stdout, qr/^Mode: desktop$/m, 'main_desktop prints the desktop mode in readable text' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $os_release = File::Spec->catfile( $tmp, 'os-release' );
    my $proc_ver   = File::Spec->catfile( $tmp, 'proc-version' );
    write_file( $os_release, qq{ID=ubuntu\nVERSION_ID="22.04"\n} );
    write_file( $proc_ver,   "plain linux kernel string\n" );

    my $stdout = q{};
    my $stderr = q{};
    open my $out, '>', \$stdout or die $!;
    open my $err, '>', \$stderr or die $!;

    my $exit = WSLg::Setup->new(
        os_release_path   => $os_release,
        proc_version_path => $proc_ver,
        stdout_fh         => $out,
        stderr_fh         => $err,
    )->main_desktop('--dry-run');

    is( $exit, 2, 'main_desktop returns exit code 2 on failure' );
    like( $stderr, qr/WSLg desktop must run inside WSL/, 'main_desktop writes the desktop error to stderr' );
}

{
    my $setup = WSLg::Setup->new;
    ok( $setup->_run_command( '/bin/sh', '-c', 'exit 0' ), 'default runner succeeds on a zero-exit command' );
}

{
    my $setup = WSLg::Setup->new(
        runner => sub { return 1; },
    );
    my $ok = eval { $setup->_run_command('false'); 1 };
    ok( !$ok, '_run_command dies on nonzero exit status' );
    like( $@, qr/^Command failed: false/, '_run_command reports the failing command' );
}

{
    my $tmp = tempdir( CLEANUP => 1 );
    my $target = File::Spec->catfile( $tmp, 'nested', 'override.conf' );
    my @commands;
    my $setup = WSLg::Setup->new(
        runner => sub { push @commands, [@_]; return 0; },
    );

    ok( $setup->_install_text_file( $target, "hello\n", '0644' ), '_install_text_file succeeds through the default temp-file installer path' );
    is( scalar @commands, 2, '_install_text_file emits the expected install commands' );
    is_deeply(
        $commands[0],
        [ 'sudo', 'install', '-d', '-m', '0755', File::Spec->catdir( $tmp, 'nested' ) ],
        '_install_text_file creates the parent directory first'
    );
    is( $commands[1][0], 'sudo', '_install_text_file installs the temp file with sudo' );
    is( $commands[1][1], 'install', '_install_text_file uses install for the final copy' );
    is( $commands[1][2], '-m', '_install_text_file passes the file mode to install' );
    is( $commands[1][3], '0644', '_install_text_file preserves the requested file mode' );
    is( $commands[1][5], $target, '_install_text_file targets the requested file path' );
    ok( !-e $commands[1][4], '_install_text_file removes the temporary file after use' );
}

done_testing;
