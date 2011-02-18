
use strict;
use warnings;
use Test;
use App::MrShell;

plan tests => 3;

my $res = eval {
   local @ARGV = (
        "-s" => qq|0 t/touch '\%h' '\%n'|,
        "-l" => "05_touch.log", '--trunc',
        "-H" => 'a',
        "-H" => 'b',
        'c3'
    );

    unless( defined(do "blib/script/mrsh") ) {
        die "mrsh failure: $!$@"
    }
};

ok( $res );
ok( -f "test_file.a.1.c3" );
ok( -f "test_file.b.1.c3" );
