
use strict;
use warnings;
use Test;
use App::MrShell;

plan tests => 2;

my ($t) = eval {
    open IN, "FILES" or die $!;
    my @files = <IN>; chomp @files;
    grep {m/touch/} @files;
};

if( not $t or not -x $t ) {
    warn "skipping touch tests";
    skip(1,1,1) for 1 .. 2;
    exit 0;
}

@App::MrShell::DEFAULT_SHELL_COMMAND = $t;

ok( eval { App::MrShell->new->queue_command("test_file")->run_queue; 1 } ) or warn $@;
ok( -f "test_file" );
