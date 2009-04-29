package App::MrShell;

use strict;
use warnings;

use Carp;
use POSIX;
use Config::Tiny;
use POE qw( Wheel::Run );
use Term::ANSIColor qw(:constants);

our $VERSION = '2.0000';
our @SSH_COMMAND = (qw(ssh -qx -o), 'BatchMode yes', '-o', 'StrictHostKeyChecking no');

# new {{{
sub new {
    my $this = bless { hosts=>[], cmd=>[], _ssh_cmd=>[@SSH_COMMAND] };

    $this;
}
# }}}
# read_config {{{
sub read_config {
    my ($this, $that) = @_;

    $this->{_conf} = Config::Tiny->read($that) if -f $that;
    $this->{groups} = {
        map { $_ => [split m/\s*,\s*/, $this->{_conf}{groups}{$_}] }
        keys %{ $this->{_conf}{groups} }
    };

    if( my ($s) = grep {defined} @{$this->{_conf}{options}}{qw(ssh_command ssh-command sshcommand ssh)} ) {
        $this->{_ssh_cmd} = [ grep {defined} ($s =~ m/["']([^"']*?)["']|(\S+)/g) ];
    }

    $this;
}
# }}}
# set_hosts {{{
sub set_hosts {
    my $this = shift;

    $this->{hosts} = [
       map { split m/\s*,\s*/ }
       map { my $k = $_; $k =~ s/^\@// ? @{$this->{groups}{$k} or die "couldn't find group: \@$k\n"} : $_ }
       @_
    ];

    my $l = 0;
    for( map { length $_ } @{ $this->{hosts} } ) {
        $l = $_ if $_>$l
    }

    $this->{_host_width} = $l;
    $this;
}
# }}}
# set_usage_error($&) {{{
sub set_usage_error($&) {
    my $this = shift;
       $this->{_usage_error} = shift;

    $this;
}
# }}}
# queue_command {{{
sub queue_command {
    my $this = shift;
    my @hosts = @{$this->{hosts}};

    unless( @hosts ) {
        if( my $e = $this->{_usage_error} ) {
            warn "Error, no hosts specified\n";
            $e->();

        } else {
            croak "set_hosts before issuing queue_command";
        }
    }

    for my $h (@hosts) {
        push @{$this->{_cmd_queue}{$h}}, \@_;
    }

    $this;
}
# }}}

# std_msg {{{
sub std_msg {
    my $this  = shift;
    my $host  = shift;
    my $cmdno = shift;
    my $fh    = shift;
    my $msg   = shift;

    print strftime('%H:%M:%S ', localtime),
        sprintf('cn:%-2d %-*s', $cmdno, $this->{_host_width}+2, "$host: "),
            ( $fh==2 ? ('[',RED,'ERR',RESET,'] ') : () ), $msg, "\n";
}
# }}}

# line {{{
sub line {
    my $this = shift;
    my $fh   = shift;
    my ($line, $wid) = @_[ ARG0, ARG1 ];
    my ($kid, $host, $cmdno, $lineno) = @{$this->{_wid}{$wid}};

    $$lineno ++;
    $this->std_msg($host, $cmdno, $fh, $line);
}
# }}}

# sigchld {{{
sub sigchld {
    my $this = shift;
    my ($kid, $host, $cmdno, @c) = @{ delete $this->{_pid}{ $_[ARG1] } || return };
    delete $this->{_wid}{ $kid->ID };

    $this->std_msg($host, $cmdno, 0, '--error--');
}
# }}}
# close {{{
sub close {
    my $this = shift;
    my $wid  = $_[ARG0];
    my ($kid, $host, $cmdno, $lineno, @c) = @{ delete $this->{_wid}{$wid} };
    delete $this->{_pid}{ $kid->PID };

    $this->std_msg($host, $cmdno, 0, BOLD.BLACK.'--eof--'.RESET) if $$lineno == 0;
    $this->start_one($_[KERNEL] => $host, $cmdno+1, @c) if @c;
}
# }}}

# start_queue {{{
sub start_queue {
    my ($this, $kernel => $host, $cmdno, $cmd, @next) = @_;

    my $kid = POE::Wheel::Run->new(
        Program     => [ @{$this->{_ssh_cmd}} => ($host, @$cmd) ],
        StdoutEvent => "child_stdout",
        StderrEvent => "child_stderr",
        CloseEvent  => "child_close",
    );

    $kernel->sig_child( $kid->PID, "child_signal" );

    my $lineno = 0;
    my $info = [ $kid, $host, $cmdno, \$lineno, @next ];
    $this->{_wid}{ $kid->ID } = $this->{_pid}{ $kid->PID } = $info;
}
# }}}

# _poe_start {{{
sub _poe_start {
    my $this = shift;

    for my $host (keys %{ $this->{_cmd_queue} }) {
        my @c = @{ $this->{_cmd_queue}{$host} };

        $this->start_queue($_[KERNEL] => $host, 1, @c);
    }

    delete $this->{_cmd_queue};
    return;
}
# }}}
# run_queue {{{
sub run_queue {
    my $this = shift;

    $this->{_session} = POE::Session->create( inline_states => {
        _start       => sub { $this->_poe_start(@_) },
        child_stdout => sub { $this->line(1, @_) },
        child_stderr => sub { $this->line(2, @_) },
        child_close  => sub { $this->close(@_) },
        child_signal => sub { $this->sigchld(@_) },
    });

    POE::Kernel->run();

    $this
}
# }}}
