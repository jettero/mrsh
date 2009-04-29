
require 5.006001;

use strict;    
use warnings;  
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::MrShell',
    VERSION_FROM  => 'MrShell.pm',
    AUTHOR        => 'Paul Miller <jettero@cpan.org>',
    EXE_FILES     => [ 'mrsh' ],

    PREREQ_PM => {
        'Config::Tiny'          => 0,
        'POE'                   => 0,
        'Term::ANSIColor'       => 0,
    },  

    ($ExtUtils::MakeMaker::VERSION ge '6.48'?
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => ['ssh'],
                resources=> {
                    repository => 'http://github.com/jettero/mrsh',
                },  
            },  

        LICENSE => 'GPL',
    ) : ()),

    clean => { FILES => 'FILES dist' },
);  

my $test_ssh = prompt("Run shell tests (runs uptime and touches files in /tmp)?", "n");

unless( $test_ssh =~ m/n/i ) {
    my @uptime = ( "/bin/uptime", "/usr/bin/uptime", "/sbin/uptime", "/usr/sbin/uptime" );
    my @touch  = ( "/bin/touch", "/usr/bin/touch", "/sbin/touch", "/usr/sbin/touch" );

    my $uptime = shift @uptime;
       $uptime = shift @uptime while @uptime and not -x $uptime;

    my $touch = shift @touch;
       $touch = shift @touch while @touch and not -x $touch;

    if( -x $touch and -x $uptime ) {
        open FILES, ">FILES" or die $!;
        print FILES "$uptime\n$touch\n";
        close FILES;

    } else {
        warn "could not find uptime and touch, skipping tests despite your wishes\n";
    }

} else { unlink "FILES" }
