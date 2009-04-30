#!/usr/bin/perl

use strict;
use warnings;

open my $log2, ">file2" or die $!;
open my $log3, ">file3" or die $!;

my $fh2 = _filtered_thingy($log2);
my $fh3 = _filtered_thingy($log3);

print $fh2 "supz2\n";
print $fh3 "supz3\n";
print $fh2 "supz2\n";
print $fh3 "supz3\n";

sub _filtered_thingy {
    unless( our $blarg ++ ) {
        eval q { 
            package myfh;
            use Symbol;
            use Tie::Handle;
            use base 'Tie::StdHandle';

            my %orig;

            sub PRINT {
                my $this = shift;
                my @them = @_;
                s/s/S/g for @them;
                print {$orig{$this}} "garh: ", @them;
            }

            sub go {
                my $pfft = gensym();
                my $it = tie *{$pfft}, __PACKAGE__ or die $!;
                $orig{$it} = shift;
                $pfft;
            }
        1} or die $@;
    }

    myfh::go(shift);
}

