package Spoon::Installer;
use strict;
use warnings;
use Spoon;
use Spoon::Utils '-base';
use IO::All;

field const class_id => 'installer';
field const extract_to => '.';

sub compress_from {
    my $self = shift;
    $self->extract_to;
}

sub new { goto &Spoon::new } # XXX Multiple inheritance workaround

sub extract_files {
    my $self = shift;
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
    my $self = shift;
    my @files = split /^__(.+)__\n/m, $self->data;
    shift @files;
    return @files;
}
        
sub data {
    my $self = shift;
    my $package = ref($self);
    local $/;
    my $data = eval "package $package; <DATA>";
    die $@ if $@;
    return $data;
}

sub file_filter { return $_[1] }

sub compress_files {
    require File::Spec;
    my $self = shift;
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
