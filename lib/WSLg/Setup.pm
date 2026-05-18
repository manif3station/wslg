package WSLg::Setup;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempfile);
use JSON::PP qw(encode_json);

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {
        env               => $args{env} || \%ENV,
        os_release_path   => $args{os_release_path} || '/etc/os-release',
        proc_version_path => $args{proc_version_path} || '/proc/version',
        stdout_fh         => $args{stdout_fh} || \*STDOUT,
        stderr_fh         => $args{stderr_fh} || \*STDERR,
        runner            => $args{runner} || sub {
            my (@cmd) = @_;
            system { $cmd[0] } @cmd;
            return $? >> 8;
        },
        installer => $args{installer},
    }, $class;
    return $self;
}

sub main_setup {
    my ( $class, @argv ) = @_;
    my $self = ref($class) ? $class : $class->new;
    my $result = eval { $self->execute_setup(@argv) };
    if ( my $error = $@ ) {
        chomp $error;
        print { $self->{stderr_fh} } "$error\n";
        return 2;
    }
    print { $self->{stdout_fh} } encode_json($result) . "\n";
    return 0;
}

sub execute_setup {
    my ( $self, @argv ) = @_;
    my $opt = $self->_parse_args(@argv);
    die "WSLg setup must run inside WSL\n" if !$self->_is_wsl;

    my $ubuntu_version = $self->_supported_ubuntu_version( $opt->{ubuntu_version} );
    my $plan           = $self->_build_plan(
        ubuntu_version  => $ubuntu_version,
        skip_snap_store => $opt->{skip_snap_store},
    );

    if ( !$opt->{dry_run} ) {
        for my $command ( @{ $plan->{commands} } ) {
            $self->_run_command(@{$command});
        }
        $self->_install_text_file(
            $plan->{service_path},
            $plan->{service_content},
            '0644',
        );
        $self->_install_text_file(
            $plan->{override_path},
            $plan->{override_content},
            '0644',
        );
    }

    return {
        mode             => 'setup',
        applied          => $opt->{dry_run} ? JSON::PP::false : JSON::PP::true,
        dry_run          => $opt->{dry_run} ? JSON::PP::true : JSON::PP::false,
        ubuntu_version   => $ubuntu_version,
        skip_snap_store  => $opt->{skip_snap_store} ? JSON::PP::true : JSON::PP::false,
        service_path     => $plan->{service_path},
        override_path    => $plan->{override_path},
        service_content  => $plan->{service_content},
        override_content => $plan->{override_content},
        commands         => [ map { join q{ }, @{$_} } @{ $plan->{commands} } ],
        shutdown_command => 'wsl.exe --shutdown',
        start_command    => $self->_start_command,
        source_note      => 'Ubuntu WSLg GNOME bootstrap based on the referenced WSLg guide',
    };
}

sub _parse_args {
    my ( $self, @argv ) = @_;
    my %opt = (
        dry_run         => 0,
        skip_snap_store => 0,
    );

    while (@argv) {
        my $arg = shift @argv;
        if ( $arg eq '--dry-run' ) {
            $opt{dry_run} = 1;
            next;
        }
        if ( $arg eq '--skip-snap-store' ) {
            $opt{skip_snap_store} = 1;
            next;
        }
        if ( $arg eq '--ubuntu-version' ) {
            die "--ubuntu-version requires a value\n" if !@argv;
            $opt{ubuntu_version} = shift @argv;
            next;
        }
        die "Unsupported option: $arg\n";
    }

    return \%opt;
}

sub _is_wsl {
    my ($self) = @_;
    return 1 if defined $self->{env}->{WSL_DISTRO_NAME} && $self->{env}->{WSL_DISTRO_NAME} ne q{};

    my $version_text = $self->_slurp( $self->{proc_version_path} );
    return $version_text =~ /microsoft/i ? 1 : 0;
}

sub _supported_ubuntu_version {
    my ( $self, $forced_version ) = @_;
    if ( defined $forced_version ) {
        return $self->_validate_supported_version($forced_version);
    }

    my %os_release = $self->_read_os_release;
    die "WSLg setup currently supports Ubuntu only\n"
      if ( !defined $os_release{ID} || $os_release{ID} ne 'ubuntu' );

    return $self->_validate_supported_version( $os_release{VERSION_ID} );
}

sub _validate_supported_version {
    my ( $self, $version ) = @_;
    die "Unable to determine Ubuntu version\n" if !defined $version || $version eq q{};
    return $version if $version eq '20.04' || $version eq '22.04' || $version eq '24.04';
    die "Unsupported Ubuntu version: $version\n";
}

sub _read_os_release {
    my ($self) = @_;
    my $text = $self->_slurp( $self->{os_release_path} );
    my %data;
    for my $line ( split /\n/, $text ) {
        next if $line !~ /=/;
        my ( $key, $value ) = split /=/, $line, 2;
        $value =~ s/^"(.*)"$/$1/;
        $data{$key} = $value;
    }
    return %data;
}

sub _build_plan {
    my ( $self, %args ) = @_;
    my $version = $args{ubuntu_version};

    my @commands = (
        [ 'sudo', 'apt', 'update' ],
        [ 'sudo', 'apt', 'upgrade', '-y' ],
    );

    if ( !$args{skip_snap_store} ) {
        push @commands, [ 'sudo', 'snap', 'install', 'snap-store' ];
    }

    my @install = ( 'sudo', 'apt', 'install', '-y', 'ubuntu-desktop' );
    if ( $version eq '20.04' || $version eq '22.04' ) {
        push @install, 'acpi-support-';
    }
    push @commands, \@install;
    push @commands, [ 'sudo', 'systemctl', 'mask', 'gdm.service' ];
    push @commands, [ 'sudo', 'systemctl', 'enable', 'wslg-fix.service' ];

    return {
        commands         => \@commands,
        service_path     => '/etc/systemd/system/wslg-fix.service',
        service_content  => $self->_service_content($version),
        override_path    => $self->_override_path($version),
        override_content => "[Service]\nExecStart=\nExecStart=/usr/bin/gnome-shell --nested\n",
    };
}

sub _service_content {
    my ( $self, $version ) = @_;
    my @lines = (
        '[Service]',
        'Type=oneshot',
        'ExecStart=-/usr/bin/umount /tmp/.X11-unix',
        'ExecStart=/usr/bin/rm -rf /tmp/.X11-unix',
        'ExecStart=/usr/bin/mkdir /tmp/.X11-unix',
        'ExecStart=/usr/bin/chmod 1777 /tmp/.X11-unix',
        'ExecStart=/usr/bin/ln -s /mnt/wslg/.X11-unix/X0 /tmp/.X11-unix/X0',
    );
    if ( $version eq '24.04' ) {
        push @lines,
          'ExecStart=/usr/bin/chmod 0777 /mnt/wslg/runtime-dir',
          'ExecStart=/usr/bin/chmod 0666 /mnt/wslg/runtime-dir/wayland-0.lock';
    }
    push @lines, '[Install]', 'WantedBy=multi-user.target';
    return join( "\n", @lines ) . "\n";
}

sub _override_path {
    my ( $self, $version ) = @_;
    if ( $version eq '20.04' ) {
        return '/etc/systemd/user/gnome-shell-wayland.service.d/override.conf';
    }
    return '/etc/systemd/user/org.gnome.Shell@wayland.service.d/override.conf';
}

sub _start_command {
    return <<'EOF';
DESKTOP_SESSION=ubuntu \
GDMSESSION=ubuntu \
GNOME_SHELL_SESSION_MODE=ubuntu \
GTK_IM_MODULE=ibus \
GTK_MODULES=gail:atk-bridge \
IM_CONFIG_CHECK_ENV=1 \
IM_CONFIG_PHASE=1 \
QT_ACCESSIBILITY=1 \
QT_IM_MODULE=ibus \
XDG_CURRENT_DESKTOP=ubuntu:GNOME \
XDG_DATA_DIRS=/usr/share/ubuntu:$XDG_DATA_DIRS \
XDG_SESSION_TYPE=wayland \
XMODIFIERS=@im=ibus \
MUTTER_DEBUG_DUMMY_MODE_SPECS=1366x768 \
gnome-session
EOF
}

sub _run_command {
    my ( $self, @cmd ) = @_;
    my $exit = $self->{runner}->(@cmd);
    die "Command failed: @cmd\n" if $exit != 0;
    return 1;
}

sub _install_text_file {
    my ( $self, $target, $content, $mode ) = @_;
    if ( $self->{installer} ) {
        return $self->{installer}->( $target, $content, $mode );
    }

    my ( $fh, $temp_path ) = tempfile();
    print {$fh} $content or die "Unable to write temporary file for $target: $!";
    close $fh or die "Unable to close temporary file for $target: $!";

    my $dir = dirname($target);
    $self->_run_command( 'sudo', 'install', '-d', '-m', '0755', $dir );
    $self->_run_command( 'sudo', 'install', '-m', $mode, $temp_path, $target );
    unlink $temp_path or die "Unable to remove temporary file $temp_path: $!";
    return 1;
}

sub _slurp {
    my ( $self, $path ) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $content;
}

1;
