use lib 't', 'lib';
use strict;
use warnings;
use Test::More 'no_plan'; 
use IO::All;

for (io('lib')->All_Files) {
    my $name = $_->name;
    $name =~ s/^lib\/(.*)\.pm$/$1/;
    $name =~ s/\//::/g;
    ok(eval "require $name; 1");
}
