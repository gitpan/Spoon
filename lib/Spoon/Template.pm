package Spoon::Template;
use strict;
use warnings;
use Spoon '-base';
use Template;

field const class_id => 'template';
field const default_include_path => [ './template' ];
field include_path => [];

sub init {
    my $self = shift;
    $self->use_class('config');
    $self->use_class('cgi');
}

sub all {
    my $self = shift;
    return ( 
        $self->config->all,
        $self->cgi->all,
    );
}

sub process {
    my $self = shift;
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

sub render {
    my $self = shift;
    my $template = shift;
    my $directives = {};
    $directives = shift if ref $_[0];

    my $include_path = $self->get_include_path;
    my $output;
    my $t = Template->new({
        %$directives,
        INCLUDE_PATH => $include_path,
        PLUGINS => $self->hub->plugins->template_lookup,
        OUTPUT => \$output,
        TOLERANT => 0,
    });
    eval {
        $t->process($template, {@_}) or die $t->error;
    };
    die "Template Toolkit error: $@" if $@;
    return $output;
}

sub get_include_path {
    my $self = shift;
    my $include_path = $self->include_path;
    @$include_path ? $include_path : $self->default_include_path;
}

1;

__DATA__

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
