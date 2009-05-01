
use strict;
use warnings;

use Test;
use App::MrShell;

plan tests => 4;

my $shell = App::MrShell->new;
my @cmd = ("a b", '%h', "c d", '%h', "e f");

DIRECT: {
    my $host  = "nombre";
    my @type1 = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(\$host, @cmd);
    ok("@type1", "a b nombre c d nombre e f");
    ok($host, "nombre");
}

INDIRECT1: {
    my $host  = "via1!nombre";
    my @type1 = $shell->set_subst_vars('%h'=>$host)->subst_cmd_vars(\$host, @cmd);
    ok("@type1", 'a b via1 a\\ b nombre c\\ d via1 a\\ b via1 a\\\\ b nombre c\\\\ d nombre e\\\\ f');
    ok($host, "nombre");
}
