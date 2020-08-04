#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
require "/run/media/tomoboy/4T-YAO1/EOS-Myanmar/scripts/time.pm";
# extract sac files from miniseed

@ARGV == 11 or die "perl $0 ev_dir start end origin evla evlo evdp ref_flag EOSsta EOSAR cal_time\n";
my ($ev_dir,$start,$end,$origin,$evla,$evlo,$evdp,$ref_flag,$cal_time,$EOSsta,$EOSAR) = @ARGV;
# ev_dir   : data directory
# start    : time in second before the reference time
# end      : time in second after the reference time
# origin   : origin time used in cal_time (used in parallel running)
# evla     : event latitude
# evlo     : event longitude
# evdp     : event depth
# ref_flag : 1 -->> reference is origin time
#            0 -->> reference is first P
# cal_time : perl script to calculat traveltime
# EOSsta   : station location file
# EOSAR    : miniseed directory


# station (full path)
#my $EOSsta = "/run/media/tomoboy/4T-YAO1/EOS-Myanmar/station/MMEOS-coord.dat";

# disk (full path)
#my $EOSAR = "/run/media/tomoboy/4T-YAO1/EOS-Myanmar/mseed";

# taup travel time calculator (full path)
#my $cal_time = "/run/media/tomoboy/4T-YAO1/EOS-Myanmar/scripts/CalTravelTime.pl";


# first arrival
my $model = "ak135";  # model
my $phase = "ttp";    # calculate P first arrival


## read stations
open(STA, "< $EOSsta") || die "Error in opening $EOSsta.\n";
my @stas = <STA>; close(STA); chomp @stas;

my %sta_coords;
for (my $i = 0; $i < @stas; $i++) {
    my ($net, $sta, $stla, $stlo, $stel) = split " ", $stas[$i];
    $sta_coords{"${net}_${sta}"} = "${stla}_${stlo}_${stel}";
}
my @stations = sort keys %sta_coords;


# read origin
my ($year, $mon, $day, $hour, $min, $sec, $msec) = split " ", &time::Get_Head($origin);
my $yday = &time::CalDOY($origin);
#print STDERR "Extracting mseed for #$year $mon $day ($yday) $hour $min $sec $msec#\n";

## start time
=pod
my $start_time = &time::Get_New_Time($origin, $start);
my $yday_start = &time::CalDOY($start_time);
my ($year_start, $mon_start, $day_start, $hour_start) = split " ", &time::Get_Head($start_time);
=cut
my ($year_start, $yday_start, $hour_start) = split " ", &find_time($origin, $start);
    #print STDERR "$origin\n$start_time\n";

## end time
=pod
my $end_time = &time::Get_New_Time($origin, $end);
my $yday_end = &time::CalDOY($end_time);
my ($year_end, $mon_end, $day_end, $hour_end) = split " ", &time::Get_Head($end_time);
=cut
my ($year_end, $yday_end, $hour_end) = split " ", &find_time($origin, $end);
    #print STDERR "$origin\n$end_time\n";


## consider the possibility that data is located at multilple files
my @years = ($year_start, $year_end);
my @ydays = ($yday_start, $yday_end);
my @hours = ($hour_start);
   @hours = ($hour_start, $hour_end) if ($hour_start != $hour_end);
for (my $i = 0; $i < @hours; $i++) {
    print STDERR "mseeds: Year $years[$i] Day $ydays[$i] Hour $hours[$i]\n";
}


# go to data directory
my $work_dir = `pwd`; chomp $work_dir;
chdir $ev_dir;


## extract sac files from mseed
for (my $j = 0; $j < @stations; $j++) {
    my ($net, $sta) = split "_", $stations[$j];
    my ($stla, $stlo, $stel) = split "_", $sta_coords{$stations[$j]};
        #print STDERR "$stla $stlo $stel $net $sta\n";

    ## reference is first-arrival instead of origin time
    if ($ref_flag == 1) {
        my ($gcarc) = split " ", `distaz $stla $stlo $evla $evlo`; chomp $gcarc;
        print STDERR "$sta: $stla $stlo $evla $evlo $evdp $gcarc\n";

        # calculate first arrival
        my @ttimes = `perl $cal_time $origin $evdp $gcarc $model $phase`; chomp @ttimes;
        my ($first_arrival, $ph) = split " ", $ttimes[0];
        if ($first_arrival ne "undef") {
            my $start_new = $first_arrival + $start;
            my $end_new   = $first_arrival + $end;
            print STDERR "$start_new $end_new $first_arrival\n";

            ($year_start, $yday_start, $hour_start) = split " ", &find_time($origin, $start_new);
            ($year_end, $yday_end, $hour_end) = split " ", &find_time($origin, $end_new);
            @years = ($year_start, $year_end);
            @ydays = ($yday_start, $yday_end);
            @hours = ($hour_start);
            @hours = ($hour_start, $hour_end) if ($hour_start != $hour_end);
        }
    }


    ## find mseed files
    my @mseeds;
    for (my $k = 0; $k < @hours; $k++) {
        ## data directory in EOS array
        ## only broadband data is used
        my $data_dir = "$EOSAR/$years[$k]/$net/$sta";
        my @chn_dirs = glob "$data_dir/H*.D"; chomp @chn_dirs;

        for (my $kk = 0; $kk < @chn_dirs; $kk++) {
            my $data_dir   = "$chn_dirs[$kk]/$ydays[$k]";
            my @mseeds_tmp = glob "$data_dir/${net}.${sta}.*.$years[$k].$ydays[$k].$hours[$k].*.mseed";
            push @mseeds, @mseeds_tmp;
        }
    }

    ## extract sac files from mseed
    if (@mseeds == 0) {
        print STDERR "No data for $origin $net $sta\n";
        next;
    }
    for (my $k = 0; $k < @mseeds; $k++) {
        `mseed2sac $mseeds[$k]`;
    }

} # for j


## go back to the current work directory
#chdir "\.\./\.\./";
chdir $work_dir;


##############################
# find the year, day of year, hour when origin is plus duration
sub find_time {
    my ($origin, $duration) = @_;

    my $new_time = &time::Get_New_Time($origin, $duration);
    my $yday     = &time::CalDOY($new_time);
    my ($year, $mon, $day, $hour) =
                            split " ", &time::Get_Head($new_time);

    return "$year $yday $hour";
}


