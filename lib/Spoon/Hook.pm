package Spoon::Hook;
use Spiffy -Base;

field 'code';
field 'pre';
field 'post';
field 'new_args';

sub returned {
    $self->{returned} = shift if @_;
    $self->{returned} ||= [];
    (@{$self->{returned}});
}

sub returned_true {
   @{$self->{returned}} && $self->{returned}[0] && 1;
}

sub cancel {
    $self->code(undef);
    return ();
}

sub hook {
    my $class = $self;
    my ($target_name, %hooks) = @_;
    my $target = $class->assert_method($target_name);
    my $pre = $hooks{pre};
    my $post = $hooks{post};
    no warnings 'redefine';
    no strict 'refs';
    *$target_name = sub {
        $pre = $class->assert_method($pre) 
          if defined $pre and not ref $pre;
        $post = $class->assert_method($post)
          if defined $post and not ref $post;
        my $hook = $class->new(
            code => $target,
            pre => $pre,
            post => $post,
        );
        $hook->returned([$hook->pre->(@_, $hook)]) 
          if $hook->pre;
        my $code = $hook->code
          or return $hook->returned;
        my $new_args = $hook->new_args;
        @_ = @$new_args 
          if $new_args;
        $hook->returned([&$code(@_)]);
        return $hook->post->(@_, $hook) 
          if $hook->post;
        return $hook->returned;
    };
}

sub assert_method {
    my $full_name = shift;
    my ($package, $method) = ($full_name) =~ /(.*)::(.*)/
      or die "Can't hook invalid fully qualified method name: '$full_name'";
    unless ($package->can('new')) {
        eval "require $package";
        undef($@);
        die "Can't hook $full_name. Can't find package '$package'"
          unless $package->can('new');
    }
    my $sub = $package . "::$method";
    return \&$sub if defined &$sub;
    no strict 'refs';
    *$sub = eval <<END;
sub { 
    package $package;
    my \$self = shift;
    \$self->SUPER::$method(\@_);
};
END
    return \&$sub;
}

__END__

=head1 NAME 

Spoon::Hook - Spoon Method Hooking Facility

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
