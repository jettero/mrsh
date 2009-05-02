#!/usr/bin/perl

use strict;
use IPC::System::Simple qw(systemx);

eval {systemx("make")} or (systemx(qw(perl Makefile.PL)) and systemx("make"));

systemx($^X, '-Iblib/lib', 'mrsh', @ARGV);

