package Spoon::Headers;
use Spoon::Base -Base;

field content_type => 'text/html';
field charset => 'UTF-8';
field expires => 'now';
field pragma => 'no-cache';
field cache_control => 'no-cache';
field redirect => '';

sub print {
    my $headers = $self->get;
    $self->utf8_encode($headers);
    print $headers;
}

sub get {
    $self->redirect
    ? CGI::redirect($self->redirect)
    : CGI::header($self->value);
}

sub value {
    (
        $self->hub->cookie->set_cookie_headers,
        -charset => $self->charset,
        -type => $self->content_type,
        -expires => $self->expires,
        -pragma => $self->pragma,
        -cache_control => $self->cache_control,
        -last_modified => $self->last_modified,
    );
}

sub last_modified {
    scalar gmtime;
}
