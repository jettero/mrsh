package App::MrShell;

use strict;
use warnings;

use Carp;
use POSIX;
use Config::Tiny;
use POE qw( Wheel::Run );
use Term::ANSIColor qw(:constants);

our $VERSION = '2.0000';
our @DEFAULT_SHELL_COMMAND = (ssh => '-o', 'BatchMode yes', '-o', 'StrictHostKeyChecking no', '-o', 'ConnectTimeout 20', '%h');

# new {{{
sub new {
    my $this = bless { hosts=>[], cmd=>[], _shell_cmd=>[@DEFAULT_SHELL_COMMAND] };

    $this;
}
# }}}

# _process_space_delimited {{{
sub _process_space_delimited {
    my $this = shift;

    return
        grep {defined} ($_[0] =~ m/["']([^"']*?)["']|(\S+)/g)
}
# }}}
# _process_hosts {{{
sub _process_hosts {
    my $this = shift;
    my @h = map { my $k = $_; $k =~ s/^\@// ? @{$this->{groups}{$k} or die "couldn't find group: \@$k\n"} : $_ } @_;

    my $o = my $l = $this->{_host_width} || 0;
    for( map { length $_ } @h ) {
        $l = $_ if $_>$l
    }
    $this->{_host_width} = $l if $l != $o;

    @h;
}
# }}}

# set_shell_command_option {{{
sub set_shell_command_option {
    my $this = shift;
    my $space_delimited = shift;

    if( $space_delimited ) {
        $this->{_shell_cmd} = ($_[0] eq "none" ? [] : [ $this->_process_space_delimited($_[0]) ]);

    } else {
        $this->{_shell_cmd} = [ @_ ];
    }

    $this;
}
# }}}
# set_group_option {{{
sub set_group_option {
    my $this  = shift;
    my $name  = shift;
    my $value = shift;

    $this->{groups}{$name} = [ $this->_process_space_delimited( $value ) ];
    $this;
}
# }}}
# set_logfile_option {{{
sub set_logfile_option {
    my $this = shift;
    my $file = shift;
    my $trunc = shift;

    unless( our $already_compiled++ ) {
        eval q {
            package App::MrShell::ANSIFilter;
            use Symbol;
            use Tie::Handle;
            use base 'Tie::StdHandle';

            my %orig;

            sub PRINT {
                my $this = shift;
                my @them = @_;
                s/\e\[[\d;]+m//g for @them;
                print {$orig{$this}} @them;
            }

            sub filtered_handle {
                my $pfft = gensym();
                my $it = tie *{$pfft}, __PACKAGE__ or die $!;
                $orig{$it} = shift;
                $pfft;
            }

        1} or die $@;
    }

    open my $log, ($trunc ? ">" : ">>"), $file or croak "couldn't open $file for write: $!";

    $this->{_log_fh} = App::MrShell::ANSIFilter::filtered_handle($log);
    $this;
}
# }}}
# set_debug_option {{{
sub set_debug_option {
    my $this = shift;
    my $val = shift;

    # -d 0 and -d 1 are the same
    # -d 2 is a level up, -d 4 is even more
    # $val==undef clears the setting

    if( not defined $val ) {
        delete $this->{debug};
        return $this;
    }

    $this->{debug} = $val ? $val : 1;
    $this;
}
# }}}

# set_usage_error($&) {{{
sub set_usage_error($&) {
    my $this = shift;
    my $func = shift;
    my $pack = caller;
    my $name = $pack . "::$func";
    my @args = @_;

    $this->{_usage_error} = sub {
         no strict 'refs';
         goto &$name;
    };

    $this->{_usage_error} = sub { no strict 'refs'; $name->(@args) };
    $this;
}
# }}}
# read_config {{{
sub read_config {
    my ($this, $that) = @_;

    $this->{_conf} = Config::Tiny->read($that) if -f $that;

    for my $group (keys %{ $this->{_conf}{groups} }) {
        $this->set_group_option( $group => $this->{_conf}{groups}{$group} );
    }

    if( my $c = $this->{_conf}{options}{'shell-command'} ) {
        $this->set_shell_command_option( 1, $c );
    }

    $this;
}
# }}}
# set_hosts {{{
sub set_hosts {
    my $this = shift;

    $this->{hosts} = [ $this->_process_hosts(@_) ];
    $this;
}
# }}}
# queue_command {{{
sub queue_command {
    my $this = shift;
    my @hosts = @{$this->{hosts}};

    unless( @hosts ) {
        if( my $h = $this->{_conf}{options}{'default-hosts'} ) {
            @hosts = $this->_process_hosts( $this->_process_space_delimited($h) );

        } else {
            if( my $e = $this->{_usage_error} ) {
                warn "Error: no hosts specified\n";
                $e->();

            } else {
                croak "set_hosts before issuing queue_command";
            }
        }
    }

    for my $h (@hosts) {
        push @{$this->{_cmd_queue}{$h}}, \@_;
    }

    $this;
}
# }}}
# run_queue {{{
sub run_queue {
    my $this = shift;

    $this->{_session} = POE::Session->create( inline_states => {
        _start       => sub { $this->poe_start(@_) },
        child_stdout => sub { $this->line(1, @_) },
        child_stderr => sub { $this->line(2, @_) },
        child_close  => sub { $this->close(@_) },
        child_signal => sub { $this->sigchld(@_) },
        stall_close  => sub { $this->_close(@_) },
        ErrorEvent   => sub { $this->error_event },
    });

    POE::Kernel->run();

    $this
}
# }}}

# std_msg {{{
sub std_msg {
    my $this  = shift;
    my $host  = shift;
    my $cmdno = shift;
    my $fh    = shift;
    my $msg   = shift;

    my $orig; {
        print strftime('%H:%M:%S ', localtime),
            sprintf('cn:%-2d %-*s', $cmdno, $this->{_host_width}+2, "$host: "),
                ( $fh==2 ? ('[',BOLD,YELLOW,'stderr',RESET,'] ') : () ), $msg, "\n";

        if( $this->{_log_fh} and not $orig ) {
            $orig = select $this->{_log_fh};
            redo;
        }
    }

    select $orig if $orig;

    $this;
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

    $this->std_msg($host, $cmdno, 0, RED.'-- error: unexpected child exit --'.RESET);
}
# }}}
# close {{{

sub close {
    my $this = shift;

    $_[KERNEL]->yield( stall_close => $_[ARG0], 0 );
}
# }}}
# _close {{{
sub _close {
    my $this = shift;
    my ($wid, $count) = @_[ ARG0, ARG1 ];

    if( $count > 3 ) {
        my ($kid, $host, $cmdno, $lineno, @c) = @{ delete $this->{_wid}{$wid} };

        $this->std_msg($host, $cmdno, 0, BOLD.BLACK.'--eof--'.RESET) if $$lineno == 0;
        $this->start_queue_on_host($_[KERNEL] => $host, $cmdno+1, @c) if @c;

        delete $this->{_pid}{ $kid->PID };

    } else {
        $_[KERNEL]->yield( stall_close => $wid, $count+1 );
    }
}
# }}}
# error_event {{{
sub error_event {
    my $this = shift;
    my ($operation, $errnum, $errstr, $wid) = @_[ARG0 .. ARG3];
    my ($kid, $host, $cmdno, @c) = @{ delete $this->{_wid}{$wid} || return };
    delete $this->{_pid}{ $kid->PID };

    $errstr = "remote end closed" if $operation eq "read" and !$errnum;
    $this->std_msg($host, $cmdno, 0, RED."-- $operation error $errnum: $errstr --".RESET);
}
# }}}

# set_subst_vars {{{
sub set_subst_vars {
    my $this = shift;
       $this->{_subst} = { @_ };

    $this;
}
# }}}
# subst_cmd_vars {{{
sub subst_cmd_vars {
    my $this = shift;
    my $hostref = shift;
    my %h = %{ delete($this->{_subst}) || {} };

    if( $$hostref =~ m/\b(?!<\\)!/ ) {
        delete $h{'%h'};
        my @hosts = split '!', $$hostref;

        for(my $i=0; $i<@_; $i++) {
            if( $_[$i] eq '%h' ) {
                splice @_, $i, 1, $hosts[0];

                for my $h (reverse @hosts[1 .. $#hosts]) {
                    splice @_, $i+1, 0, @_[0 .. $i-1] => $h;
                    s/\\/\\\\/g         for @_[$i+1 .. $#_];
                    s/(?<=[^\\]) /\\ /g for @_[$i+1 .. $#_];
                }
            }
        }

        $$hostref = $hosts[-1];

    } else {
        $h{'%h'} =~ s/\\!/!/g;
    }

    if( $this->{debug} ) {
        my @cmd = map {exists $h{$_} ? $h{$_} : $_} @_;

        my @dt = map {"'$_'"} @cmd;
        $this->std_msg($$hostref, $h{'%c'}, 0, BOLD.BLACK."DEBUG: exec(@dt)".RESET);

        return @cmd;
    }

    map {exists $h{$_} ? $h{$_} : $_} @_;
}
# }}}
# start_queue_on_host {{{
sub start_queue_on_host {
    my ($this, $kernel => $host, $cmdno, $cmd, @next) = @_;

    # NOTE: used (and deleted) by subst_cmd_vars
    $this->{_subst}{'%h'} = $host;
    $this->{_subst}{'%n'} = $cmdno;

    my $kid = POE::Wheel::Run->new(
        Program     => [ $this->subst_cmd_vars(\$host, @{$this->{_shell_cmd}} => @$cmd) ],
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
# poe_start {{{
sub poe_start {
    my $this = shift;

    for my $host (keys %{ $this->{_cmd_queue} }) {
        my @c = @{ $this->{_cmd_queue}{$host} };

        $this->start_queue_on_host($_[KERNEL] => $host, 1, @c);
    }

    delete $this->{_cmd_queue};
    return;
}
# }}}
