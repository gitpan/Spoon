package Spoon;
use strict;
use warnings;
our $VERSION = '0.16';
use Spoon::Base '-Base';

const class_id => 'main';
const config_class => 'Spoon::Config';
field using_debug => 0;

sub paired_arguments { qw(-config_class) }

sub load_hub {
    my ($args, @config_files) = $self->parse_arguments(@_);
    my $config_class = $args->{-config_class} || $self->config_class;
    eval "require $config_class";
    my $config = $config_class->new(@config_files);
    my $hub_class = $config->hub_class;
    eval "require $hub_class";
    my $hub = $hub_class->new;
    $hub->config($config);
    $hub->init;
    $config->hub($hub);
    $hub->config_files(\@config_files);
    $hub->main($self);
    $self->hub($hub);
    $self->init;
    no warnings;
    $main::HUB = $hub;
    return $hub;
}

sub debug {
    no warnings;
    if ($ENV{GATEWAY_INTERFACE}) {
        eval q{use CGI::Carp qw(fatalsToBrowser)}; die $@ if $@;
        *CORE::GLOBAL::die = sub { goto &CGI::Carp::confess };
    }
    else {
        require Carp;
        *CORE::GLOBAL::die = sub { goto &Carp::confess };
    }
    $self->using_debug(1);
    return $self;
}

1;

__END__

=head1 NAME

Spoon - A Spiffy Application Building Framework

=head1 SYNOPSIS

    Out of the Cutlery Drawer
    And onto the Dinner Table

=head1 DESCRIPTION

Spoon is an Application Framework that is designed primarily for
building Social Software web applications. The Kwiki wiki software is
built on top of Spoon.

Spoon::Base is the primary base class for all the Spoon::* modules.
Spoon.pm inherits from Spiffy.pm.

Spoon is not an application in and of itself. (As compared to Kwiki)
You need to build your own applications from it.

=head1 SEE ALSO

Kwiki, Spork, Spiffy

=head1 DEDICATION

This project is dedicated to the memory of Iain "Spoon" Truskett.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
