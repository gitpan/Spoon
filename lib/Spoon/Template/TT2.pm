package Spoon::Template::TT2;
use strict;
use warnings;
use Spoon::Template '-Base';
use Template 2.0;

sub render {
    my $template = shift;
    my $directives = {};
    $directives = shift if ref $_[0];

    my $output;
    my $t = Template->new({
        %$directives,
        INCLUDE_PATH => $self->path,
        OUTPUT => \$output,
        TOLERANT => 0,
    });
    eval {
        $t->process($template, {@_}) or die $t->error;
    };
    die "Template Toolkit error:\n$@" if $@;
    return $output;
}

1;

__DATA__

=head1 NAME

Spoon::Template::TT2 - Spoon Template Toolkit Base Class

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
