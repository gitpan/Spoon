package Spoon::Installer;
use strict;
use warnings;
use Spoon::Base '-Base';

const class_id => 'installer';
const extract_to => '.';

sub compress_from {
    $self->extract_to;
}

sub extract_files {
    my @files = $self->get_packed_files;
    while (@files) {
        my ($file_name, $file_contents) = splice(@files, 0, 2);
        my $locked = $file_name =~ s/^!//;
        my $file_path = join '/', $self->extract_to, $file_name;
        my $file = io->file($file_path)->assert;
        if ($locked and -f $file_path) {
            warn "  Skipping $file (already exists)\n";
            next;
        }
        if (-f $file_path and $file->scalar eq $file_contents) {
            warn "  Skipping $file (unchanged)\n";
            next;
        }
        warn "  - $file\n";
        $self->set_file_content($file_path, $file_contents);
    }
}

sub set_file_content {
    my $path = shift;
    my $content = shift;
    $content = $self->base64_decode($content)
      if $path =~ /\.(gif|jpg|png)$/;
    $content = $self->fix_hashbang($content)
      if $path =~ /\.(pl|cgi)$/;
    io($path)->assert->print($content);
}

sub fix_hashbang {
    require Config;
    my $content = shift;
    $content =~ s/^#!.*\n/$Config::Config{startperl} -w\n/;
    return $content;
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
    die "No DATA section found for $package."
      unless $data;
    return $data;
}

sub compress_files {
    require File::Spec;
    my $source_dir = shift;
    my $new_pack = '';
    my @files = $self->get_packed_files;
    my $first_file = $files[0]
      or return;
    my $directory = $self->compress_from;
    while (@files) {
        my ($file_name, $file_contents) = splice(@files, 0, 2);
        my $locked = $file_name =~ s/^!// ? '!' : '';
        my $source_path = 
          File::Spec->canonpath("$source_dir/$directory/$file_name");
        die "$file_name does not exist as $source_path" 
          unless -f $source_path;
        my $content = $locked 
        ? $file_contents
        : $self->get_file_content($source_path);
        $new_pack .= "__$locked${file_name}__\n$content";
    }
    my $module = ref($self) . '.pm';
    $module =~ s/::/\//g;
    my $module_path = $INC{$module} or die;
    my $module_text = io($module_path)->scalar;
    my ($module_code) = split /^__\Q$first_file\E__\n/m, $module_text;
    ($module_code . $new_pack) > io($module_path);
}

sub get_file_content {
    my $path = shift;
    my $content = io($path)->scalar;
    $content = $self->base64_encode($content)
      if $path =~ /\.(gif|jpg|png)$/;
    $content = $self->unfix_hashbang($content)
      if $path =~ /\.(pl|cgi)$/;
    $content .= "\n"
      unless $content =~ /\n\z/;
    return $content;
}

sub unfix_hashbang {
    my $content = shift;
    $content =~ s/^#!.*\n/#!\/usr\/bin\/perl\n/;
    return $content;
}

sub compress_lib {
    die "Must be run from the module source code directory\n"
      unless -d "lib";
    my $source_dir = shift
      or die "No source directory specified\n";
    die "Invalid source directory '$source_dir'\n"
      unless -d $source_dir;
    map {
        my $class_name = $_;
        my $class_id = $class_name->class_id;
        $self->hub->config->add_config(
            +{ "${class_id}_class" => $class_name }
        );
        warn "Compressing $class_name\n";
        $self->hub->load_class($class_id)->compress_files($source_dir);
    }
    grep {
        my $name = $_;
        eval "require $name";
        UNIVERSAL::isa($name, 'Spoon::Installer')
          and $name !~ /::(Installer|Theme)$/; #XXX
    } map {
        my $name = $_->name;
        $name =~ s/^lib\/(.*)\.pm$/$1/;
        $name =~ s/\//::/g;
        $name;
    } io('lib')->All_Files;
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
