package Spoon::Utils;
use strict;
use warnings;
use Spiffy '-base';
field const directory_perms => 0755;

sub assert_filepath {
    my $self = shift;
    my $filepath = shift;
    return unless $filepath =~ s/(.*)[\/\\].*/$1/;
    return if -e $filepath;
    $self->assert_directory($filepath);
}

sub assert_directory {
    my $self = shift;
    my $directory = shift;
    require File::Path;
    umask 0000;
    File::Path::mkpath($directory, 0, $self->directory_perms);
}

sub remove_tree {
    my $self = shift;
    my $directory = shift;
    require File::Path;
    umask 0000;
    File::Path::rmtree($directory);
}

1;

__END__
