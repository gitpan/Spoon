package Spoon::Template;
use strict;
use warnings;
use Spoon '-Base';
use Template;

const class_id => 'template';
const default_path => [ './template' ];
field path => [];
stub 'render';

sub init {
    $self->use_class('config');
    $self->use_class('cgi')
      if $self->is_in_cgi;
    $self->add_path(@{$self->default_path});
}

sub all {
    return ( 
        $self->config->all,
        $self->is_in_cgi ? ($self->cgi->all) : (),
        hub => $self->hub,
    );
}

sub add_path {
    splice @{$self->path}, 0, 0, @_;
}

sub remove_path {
    my $path = shift;
    $self->path([grep {$_ ne $path} @{$self->path}]);
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
