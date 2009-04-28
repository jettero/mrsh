package App::MrShell;

use strict;
use warnings;

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

    if( my ($s) = grep {defined} @{$this->{_conf}}{qw(ssh_command ssh-command sshcommand ssh)} ) {
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
       map { my $k = $_; $k =~ s/^\@// ? @{$this->{gropus}{$k}||[]} : $_ }
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
# run_command {{{
sub run_command {
    my $this = shift;

    push @{$this->{cmd}}, \@_;

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
        sprintf('%2d %-*s', $cmdno, $this->{_host_width}+5, "$host($fh): "),
            ($fh==2 ? RED : $fh==0 ? (BOLD, BLACK) : () ),
                $msg, RESET, "\n";
}
# }}}

# line {{{
sub line {
    my $this = shift;
    my $fh   = shift;
    my ($line, $wid) = @_[ ARG0, ARG1 ];
    my ($kid, $host, $cmdno) = @{$this->{_wid}{$wid}};

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
    my ($kid, $host, $cmdno, @c) = @{ delete $this->{_wid}{$wid} };
    delete $this->{_pid}{ $kid->PID };

  # $this->std_msg($host, $cmdno, 0, '--eof--');
    $this->start_one($_[KERNEL] => $host, $cmdno+1, @c) if @c;
}
# }}}

# start_one {{{
sub start_one {
    my ($this, $kernel => $host, $cmdno, $cmd, @next) = @_;

    my $kid = POE::Wheel::Run->new(
        Program     => [ @{$this->{_ssh_cmd}} => ($host, @$cmd) ],
        StdoutEvent => "child_stdout",
        StderrEvent => "child_stderr",
        CloseEvent  => "child_close",
    );

    $kernel->sig_child( $kid->PID, "child_signal" );

    my $info = [ $kid, $host, $cmdno, @next ];
    $this->{_wid}{ $kid->ID } = $this->{_pid}{ $kid->PID } = $info;
}
# }}}

# _poe_start {{{
sub _poe_start {
    my $this = shift;

    my @c = @{ delete $this->{cmd} || [] };
    if( @c ) {
        for my $host (@{ $this->{hosts} }) {
            $this->start_one($_[KERNEL] => $host, 1, @c);
        }
    }
}
# }}}
# run_poe {{{
sub run_poe {
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
