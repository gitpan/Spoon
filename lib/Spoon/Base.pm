package Spoon::Base;
use strict;
use warnings;
use IO::All 0.31 ();
use Spiffy 0.20 qw(-Base);
# use Spiffy qw(-XXX -yaml);
our @EXPORT = qw(io);

sub io() { IO::All->new(@_) }

sub init { }
sub pre_process { }
sub post_process { }

field 'hub';
field 'used_classes' => [];
field 'encoding';

sub use_class {
    my ($class_id) = @_;
    Carp::confess("No hub in '$class_id' object")  
      unless $self->hub;
    $self->hub->load_class($class_id);
    my $package = ref($self);
    field -package => $package, $class_id;
    $self->$class_id($self->hub->$class_id);
    push @{$self->used_classes}, $class_id;
}       
        
sub use_cgi {
    my $class = shift
      or die "use_cgi requires a class name";
    eval qq{require $class};
    my $package = ref($self);
    field -package => $package, 'cgi';
    my $object = $class->new(hub => $self->hub);
    $object->init;
    $self->cgi($object);
}

sub is_in_cgi {
    defined $ENV{GATEWAY_INTERFACE};
}

sub have_plugin {
    my $hub = $self->class_id eq 'hub'
    ? $self
    : $self->hub;
    eval { $hub->load_class(shift) }
}
    
our ($UPPER, $LOWER, $ALPHANUM, $WORD, $WIKIWORD);
our @EXPORT_OK = qw($UPPER $LOWER $ALPHANUM $WORD $WIKIWORD);
our %EXPORT_TAGS = 
  (char_classes => [qw($UPPER $LOWER $ALPHANUM $WORD $WIKIWORD)]);
if ($] < 5.008) {
    $UPPER    = "A-Z\xc0-\xde";
    $LOWER    = "a-z\xdf-\xff";
    $ALPHANUM = "A-Za-z0-9\xc0-\xff";
    $WORD     = "A-Za-z0-9\xc0-\xff_";
    $WIKIWORD = $WORD;
}
else {
    $UPPER    = '\p{UppercaseLetter}';
    $LOWER    = '\p{LowercaseLetter}';
    $ALPHANUM = '\p{Letter}\p{Number}\pM';
    $WORD     = '\p{Letter}\p{Number}\p{ConnectorPunctuation}\pM';
    $WIKIWORD = "$UPPER$LOWER\\p{Number}\\p{ConnectorPunctuation}\\pM";
}

sub cleanup {
    for my $class_id (@{$self->used_classes}, 'hub') {
        $self->$class_id(undef);
    }
}

sub env_check {
    my $variable = shift;
    die "Environment variable '$variable' not set"
      unless defined $ENV{$variable};
}

sub dumper_to_file {
    my $path = shift;
    require Data::Dumper;
    no warnings;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = (@_ == 1) ? 1 : 0;
    local $Data::Dumper::Sortkeys = 1;
    io("$path")->assert->print(Data::Dumper::Dumper(@_));
}

# Codecs and Escaping
my $use_utf8;
sub use_utf8 {
    $use_utf8 = shift if @_;
    return $use_utf8 if defined($use_utf8);
    $use_utf8 = $] < 5.008 ? 0 : 1;
}

# sub loc {
#     my $i18n_class = $self->hub->config->i18n_class or die;
#     eval "use $i18n_class; 1" or return $_[0];
#     $i18n_class->initialize($self->use_utf8 || 0);
#     return $i18n_class->loc(@_);
# }

sub utf8_decode {
    utf8::decode($_[0]) if $self->use_utf8 and defined $_[0];
    return $_[0] if defined wantarray;
}

sub utf8_encode {
    utf8::encode($_[0]) if $self->use_utf8 and defined $_[0];
    return $_[0] if defined wantarray;
}

sub uri_escape {
    my $data = shift;
    $self->utf8_encode($data);
    return CGI::Util::escape($data);
}

sub uri_unescape {
    my $data = shift;
    $data = CGI::Util::unescape($data);
    $self->utf8_decode($data);
    return $data;
}

# The CGI.pm version is broken in Chinese
sub html_escape {
    my $val = shift;
    $val =~ s/&/&#38;/g;
    $val =~ s/</&lt;/g; 
    $val =~ s/>/&gt;/g;
    $val =~ s/\(/&#40;/g;
    $val =~ s/\)/&#41;/g;
    $val =~ s/"/&#34;/g;
    $val =~ s/'/&#39;/g;
    return $val;
}

sub html_unescape { 
    CGI::unescapeHTML(shift);
}

sub base64_encode {
    require MIME::Base64;
    MIME::Base64::encode_base64(@_);
}

sub base64_decode {
    require MIME::Base64;
    MIME::Base64::decode_base64(@_);
}

sub call_hooks {
    my @params = @_ ? splice(@_, 1) : ();
    my $hooks = $self->hub->registry->lookup
                     ->{join('_', $self->class_id, 'hook', @_)} or return;
    for my $method (sort keys %$hooks) {
        my $class_id = $hooks->{$method}[0];
        $self->hub->load_class($class_id)->$method($self, @params);
    }
}

1;

__END__

=head1 NAME 

Spoon::Base - Generic Spoon Base Class

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
