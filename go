#!/bin/bash

set -e 
make || perl Makefile.PL && make

perl -Iblib/lib ./mrsh $*

