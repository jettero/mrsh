
require 5.006001;

use strict;    
use warnings;  
use ExtUtils::MakeMaker;

my $test_ssh = prompt("Run ssh tests (runs uptime and touches files in /tmp)?", "n");

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
);  

1;

