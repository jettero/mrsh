package t::BorkedX;

BEGIN {
    $^X = "wtfmrsh" if $ENV{_TEST_THIS_MADNESS};

    if( $^X =~ m/mrsh/ ) {
        print "1..0 # SKIP Why would your \$^X contain mrsh and not the running Perl?  I very much doubt mrsh will work on your platform, but I'm not willing to test it there either (unless you can explain that to me http://goo.gl/gbb3t).\n";
        exit;
    }
}

1;
