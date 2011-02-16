
use strict;
use warnings;
use t::BorkedX;
use Test;

plan tests => 1;

ok( eval "use App::MrShell; 1" );
