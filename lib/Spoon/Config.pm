package Spoon::Config;
use strict;
use warnings;
use Spoon '-base';

field const class_id => 'config';

sub all {
    my $self = shift;
    return %$self;
}

sub new {
    my $class = shift;
    my (@configs) = @_;
    my $self = bless {}, $class;
    my $config_hash = $self->default_config;
    for my $config (@configs) {
        my $hash = ref $config
        ? $config
        : do {
            die "Invalid name for config file '$config'\n"
              unless $config =~ /\.(\w+)$/;
            my $extension = lc($1);
            my $method = "parse_$extension\_file";
            $self->$method($config);
        };
        for my $key (keys %$hash) {
            $config_hash->{$key} = $hash->{$key};
        }
    }
    my $config_class = $config_hash->{config_class}
      or die "config_class not defined in configuration file(s)\n";
    eval qq{ require $config_class }; die $@ if $@;
    $self = bless $config_hash, $config_class;
    attribute($_) for keys %$self;
    $self->init;
    return $self;
}

sub parse_file {
    my $self = shift;
    $self->parse_yaml_file(@_);
}

sub parse_yaml_file {
    my $self = shift;
    my $file = shift;
    open CONFIG, $file
      or die "Can't open $file for input:\n$!";
    my $yaml = do {local $/; <CONFIG>};
    close CONFIG;
    $self->parse_yaml($yaml);
}

sub parse_yaml {
    my $self = shift;
    my $yaml = shift;
    my $hash = {};
    my $latest_key = '';
    for (split /\n/, $yaml) {
        if (/^-\s*(.*)$/) {
            $hash->{$latest_key} = [] unless ref $hash->{$latest_key};
            push @{$hash->{$latest_key}}, $1;
        }
        elsif (/(.*?)\s*:\s+(.*?)\s*$/ or /(.*?):\s*()$/) {
            $hash->{$1} = $2;
            $latest_key = $1;
        }
    }
    return $hash;
}

sub default_config {
    {
        main_class => 'Spoon',
        hub_class => 'Spoon::Hub',
        config_class => 'Spoon::Config',
        registry_class => 'Spoon::Registry',
        cgi_class => 'Spoon::CGI',
        formatter_class => 'Spoon::Formatter',
        template_class => 'Spoon::Template',
    }
}

1;

__END__

=head1 NAME 

Spoon::Config - Spoon Configuration Base Class

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
