package Spoon::Cookie;
use strict;
use warnings;
use Spoon::Base '-Base';
use CGI qw(-no_debug);

field 'preferences';
field 'cookie_jar' => {};

sub init {
    $self->use_class('config');
    $self->fetch();
}

sub header {
    CGI::header($self->header_values);
}

sub header_values {
    (
        $self->set_cookie_headers,
        -charset => $self->config->encoding,
        $self->content_type,
        -expires => 'now',
        -pragma => 'no-cache',
        -cache_control => 'no-cache',
        -last_modified => scalar gmtime,
    );
}

sub content_type {
    (-type => 'text/html');
}

sub write {
    my ($cookie_name, $hash) = @_;
    require Storable;
    $self->cookie_jar->{$cookie_name} = $hash;
}

sub read {
    my $cookie_name = shift;
    my $cookie_jar = $self->cookie_jar;
    my $cookie = $cookie_jar->{$cookie_name};
    $cookie ||= {};
    return $cookie;
}

sub set_cookie_headers {
    my $cookie_jar = $self->cookie_jar;
    return () unless keys %$cookie_jar;
    my $cookies = [];
    @$cookies = map {
	CGI::cookie(
            -name => $_,
            -value => Storable::freeze($cookie_jar->{$_}),
            $self->path,
            $self->expiration,
        );
    } keys %$cookie_jar;
    return @$cookies ? (-cookie => $cookies) : ();
}

sub path {
    ();
}

sub expiration {
    (-expires => '+5y');
}

sub fetch {
    require Storable;
    my $cookie_jar = { 
        map { 
            my $object = eval { Storable::thaw(CGI::cookie($_)) };
            $@ ? () : ($_ => $object) 
        } CGI::cookie() 
    };
    $self->cookie_jar($cookie_jar);
}

1;

__END__

=head1 NAME 

Spoon::Cookie - Spoon Cookie Base Class

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
