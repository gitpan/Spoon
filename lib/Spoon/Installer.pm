package Spoon::Installer;
use strict;
use warnings;
use Spoon;
use Spoon::Utils '-Base';

const class_id => 'installer';
const extract_to => '.';

sub compress_from {
    $self->extract_to;
}

sub new { goto &Spoon::new } # XXX Multiple inheritance workaround

sub extract_files {
    my @files = $self->get_packed_files;
    while (@files) {
        my ($file_name, $file_contents) = splice(@files, 0, 2);
        $file_name = join '/', $self->extract_to, $file_name;
        $self->assert_filepath($file_name);
        $file_contents = $self->file_filter($file_contents);
        $file_contents > io($file_name);
    }
}

sub get_packed_files {
    my @files = split /^__(.+)__\n/m, $self->data;
    shift @files;
    return @files;
}
        
sub data {
    my $package = ref($self);
    local $/;
    my $data = eval "package $package; <DATA>";
    die $@ if $@;
    return $data;
}

sub file_filter { return shift }

sub compress_files {
    require File::Spec;
    my $source_dir = shift;
    my %source_files = map {
        ($_->name, scalar $_->slurp)
    } io($source_dir)->All_Files;
    my $new_pack = '';
    my @files = $self->get_packed_files;
    my $first_file = $files[0];
    my $directory = $self->compress_from;
    while (@files) {
        my ($file_name, $file_contents) = splice(@files, 0, 2);
        my $source_path = 
          File::Spec->canonpath("$source_dir/$directory/$file_name");
        die "$file_name does not exist as $source_path" 
          unless defined $source_files{$source_path};
        $new_pack .= "__${file_name}__\n$source_files{$source_path}";
    }
    my $module = ref($self) . '.pm';
    $module =~ s/::/\//g;
    my $module_path = $INC{$module} or die;
    my $module_text < io($module_path);
    my ($module_code) = split /^__\Q$first_file\E__\n/m, $module_text;
    ($module_code . $new_pack) > io($module_path);
}

1;

__END__

=head1 NAME 

Spoon::Installer - Spoon Installer Class

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
