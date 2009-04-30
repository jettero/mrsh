#!/usr/bin/perl

use strict;
use warnings;

my $fh = _filtered_thingy();
print $fh "supz\n";

sub _filtered_thingy {
    unless( our $blarg ) {
        eval q { 
            package myfh;
            use Symbol;
            use Tie::Handle;
            use base 'Tie::StdHandle';

            sub PRINT {
                my $this = shift;
                my @them = @_;
                s/s/S/g for @them;
                print "garh: ", @them;
            }

            sub go {
                my $pfft = gensym();
                tie *{$pfft}, __PACKAGE__ or die $!;
                $pfft;
            }
        1} or die $@;
    }

    myfh::go();
}

