package App::MrShell;

use strict;
use warnings;

use Config::Tiny;
use Symbol qw(gensym);
use POE qw( Wheel::Run );

our $VERSION = '2.0000';
our @SSH_COMMAND = (qw(ssh -qx -o), 'BatchMode yes', '-o', 'StrictHostKeyChecking no');

sub new {
    my $this = bless {};

    # POE session stuff here

    $this;
}

sub read_config {
    my ($this, $that) = @_;

    $this->{_conf} = Config::Tiny->read($that) if -f $that;
    $this->{groups} = {
        map { $_ => [split m/\s*,\s*/, $this->{_conf}{groups}{$_}] }
        keys %{ $this->{_conf}{groups} }
    };

    $this;
}

sub set_hosts {
    my $this = shift;

    $this->{hosts} = [
       map { split m/\s*,\s*/ }
       map { my $k = $_; $k =~ s/^\@// ? @{$this->{gropus}{$k}||[]} : $_ }
       @_
    ];

    $this;
}

sub run_command {
    my $this = shift;

    # POE::Wheel::Run stuff here

    $this;
}

sub show_result {
    my $this = shift;

    0;
}
