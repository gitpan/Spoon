package Spoon::Cookie;
use strict;
use warnings;
use Spoon::Base '-Base';
use CGI qw(-no_debug);

field 'preferences';
field 'jar' => {};

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
        -charset => 'UTF-8',
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
    $self->jar->{$cookie_name} = $hash;
}

sub read {
    my $cookie_name = shift;
    my $jar = $self->jar;
    my $cookie = $jar->{$cookie_name};
    $cookie ||= {};
    return $cookie;
}

sub set_cookie_headers {
    my $jar = $self->jar;
    return () unless keys %$jar;
    my $cookies = [];
    @$cookies = map {
	CGI::cookie(
            -name => $_,
            -value => Storable::freeze($jar->{$_} || {}),
            $self->path,
            $self->expiration,
        );
    } keys %$jar;
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
    my $jar = { 
        map { 
            my $object = eval { Storable::thaw(CGI::cookie($_)) };
            $@ ? () : ($_ => $object) 
        } CGI::cookie() 
    };
    $self->jar($jar);
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
