package App::MrShell;

use strict;
use warnings;

# use Config::Tiny; # this is probably smarter for groups than DBM::Deep
# use DBM::Deep;
# use Term::ReadLine;

use IO::Select;
use IPC::Open3 qw(open3);

our $VERSION = '2.0000';

sub new { bless {} }

sub set_hosts {
    my $this = shift;
       $this->{_hosts} = \@_;

    $this;
}

sub run_command {
    my $this = shift;

    $this;
}

sub show_result {
    my $this = shift;

    0;
}
