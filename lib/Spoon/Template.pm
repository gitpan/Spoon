package Spoon::Template;
use strict;
use warnings;
use Spoon '-Base';
use Template;

const class_id => 'template';
const default_include_path => [ './template' ];
field include_path => [];
stub 'render';

sub init {
    $self->use_class('config');
    $self->use_class('cgi')
      if $ENV{GATEWAY_INTERFACE};
}

sub all {
    return ( 
        $self->config->all,
        $ENV{GATEWAY_INTERFACE} ? ($self->cgi->all) : (),
    );
}

sub process {
    my $template = shift;
    my %vars = @_;
    my $directives = {};
    for my $key (keys %vars) {
        if ($key =~ /^-([A-Z_]+)$/) {
            $directives->{$1} = $vars{$key};
            delete $vars{$key};
        }
    }
    my @vars = (
        $self->all,
        %vars,
    );
    my @templates = (ref $template eq 'ARRAY')
      ? @$template 
      : $template;
    return join '', map {
        $self->render($_, $directives, @vars)
    } @templates;
}

sub get_include_path {
    my $include_path = $self->include_path;
    @$include_path ? $include_path : $self->default_include_path;
}

1;

__END__

=head1 NAME 

Spoon::Template - Spoon Template Base Class

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
