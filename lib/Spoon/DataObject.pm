package Spoon::DataObject;
use strict;
use warnings;
use Spoon::Base '-base';

stub 'class_id';
field 'id';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->hub(shift);
    $self->id(shift);
    return $self;
}   

1;

__DATA__

=head1 NAME

Spoon::DataObject - Spoon Data Object Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
