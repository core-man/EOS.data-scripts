#! /usr/bin/perl
use strict;
use warnings;
# rename seismic waveforms, e.g., MM.EW01..BHZ.SAC

@ARGV == 1 || die "Usage: perl $0 dirname\n";
my ($dir) = @ARGV;
# dir : data directory


my $workdir = `pwd`; chomp $workdir;
chdir $dir;

foreach my $file (glob "*.SAC") {
    my ($net, $sta, $loc, $chn) = (split /\./, $file)[0..3];

    # some stations may have a network name of EM, instead of MM
    #rename $file, "$net.$sta.$loc.$chn.SAC";
    rename $file, "MM.$sta.$loc.$chn.SAC";
    #rename $file, "EM.$sta.$loc.$chn.SAC";
}

chdir $workdir;

