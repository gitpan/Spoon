package Spoon;
use Spoon::Base -Base;
our $VERSION = '0.20';

const class_id => 'main';
const config_class => 'Spoon::Config';
field using_debug => 0;
field 'hub';

sub paired_arguments { qw(-config_class) }

sub load_hub {
    return $self->hub
      if $self->hub;
    $self->hub($self->new_hub(@_));
}

sub new_hub {
    my ($args, @config_files) = $self->parse_arguments(@_);
    my $config_class = $args->{-config_class} || $self->config_class;
    eval "require $config_class"; die $@ if $@;
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
    return $hub;
}

sub debug {
    no warnings;
    if ($self->is_in_cgi) {
        eval q{use CGI::Carp qw(fatalsToBrowser)}; die $@ if $@;
        $SIG{__DIE__} = sub { CGI::Carp::confess(@_) }
    }
    else {
        require Carp;
        $SIG{__DIE__} = sub { Carp::confess(@_) }
    }
    $self->using_debug(1);
    return $self;
}

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

Kwiki, Spork, Spiffy, IO::All

=head1 DEDICATION

This project is dedicated to the memory of Iain "Spoon" Truskett.

=head1 CREDIT

Dave Rolsky and Chris Dent have made major contributions to this code
base. Of particular note, Dave removed the memory cycles from the hub
architecture, allowing safe use with mod_perl.

(Dave, Chris and myself currently work at Socialtext, where this
framework is heavily used.)

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
