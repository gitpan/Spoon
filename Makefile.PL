use inc::Module::Install;

name('Spoon');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Out of the Cutlery Drawer');
license('perl');
version_from('lib/Spoon.pm');

requires(qw(
    perl 5.6.1
    Spiffy 0.19
    IO::All 0.30
    Template 2.0
));

&WriteAll();
