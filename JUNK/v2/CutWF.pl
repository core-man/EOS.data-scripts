#!/usr/bin/perl
use strict;
use warnings;
# cut seismic waveforms to the right time window,
# because EOS store 1-h data in single mseed file

@ARGV == 6 || die "Usage: perl $0 dirname start end origin ref_flag cal_time\n";
my ($dir, $start, $end, $origin, $ref_flag, $cal_time) = @ARGV;
# dir   : data directory
# start : time in second before the reference time
# end   : time in second after the reference time
# origin: origin time used in cal_time (used in parallel running)
# ref_flag : 1 -->> reference is origin time
#            0 -->> reference is first P
# cal_time : perl script to calculat traveltime


# taup travel time calculator (full path)
#my $cal_time = "/run/media/tomoboy/4T-YAO1/EOS-Myanmar/scripts/CalTravelTime.pl";

# first arrival
my $model = "ak135";  # model
my $phase = "ttp";    # calculate P first arrival


my $workdir = `pwd`; chomp $workdir;
chdir $dir;


=pod
# check if the seismic data is not within the time window
# flag == 1   within
# flag == 0   outside
my $flag = 1;
foreach (glob "*.SAC") {
    chomp;
    my (undef, $b, $e) = split " ", `saclst b e f $_`;
    if ($b > $end || $e < $start) {
        $flag = 0;
        last;
    }
}
=cut

=pod
open(SAC, "| sac");
print SAC "cuterr u \ncut $start $end \n";

if ($flag) {
    print SAC "r *.SAC \n";
    print SAC "w over \n"; }
else {
    foreach (glob "*.SAC") {
        chomp;
        my (undef, $b, $e) = split " ", `saclst b e f $_`;
        if ($b > $end || $e < $start) {
            unlink $_; }
        else {
            print SAC "r $_ \n";
            print SAC "w over \n";
        }
    }
}
=cut


# default reference time is origin
my ($start_new, $end_new) = ($start, $end);

open(SAC, "| sac");
print SAC "cuterr u \n";

foreach (glob "*.SAC") {
    chomp;

    # reference is first-arrival instead of origin time
    if ($ref_flag == 1) {
        my (undef,$stla,$stlo,$evla,$evlo,$evdp) = split " ",
                             `saclst stla stlo evla evlo evdp f $_`;
        my ($gcarc) = split " ", `distaz $stla $stlo $evla $evlo`; chomp $gcarc;
        print STDERR "$_: $stla $stlo $evla $evlo $evdp $gcarc\n";

        # calculate first arrival
        my @ttimes = `perl $cal_time $origin $evdp $gcarc $model $phase`; chomp @ttimes;
        my ($first_arrival, $ph) = split " ", $ttimes[0];
        print STDERR "$first_arrival $ph\n";
        next if ($first_arrival eq "undef");

        $start_new = $first_arrival + $start;
        $end_new   = $first_arrival + $end;
        print STDERR "$start_new $end_new $first_arrival\n";
    }

    my (undef, $b, $e) = split " ", `saclst b e f $_`;

    if ($b > $end_new || $e < $start_new) {
        unlink $_;
    }
    else {
        print SAC "cut $start_new $end_new \n";
        print SAC "r $_ \n";
        print SAC "w over \n";
    }

}

print SAC "quit \n";
close(SAC);


chdir $workdir;


