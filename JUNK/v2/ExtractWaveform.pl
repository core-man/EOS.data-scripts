#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
#require "/run/media/tomoboy/4T-YAO1/EOS-Myanmar/scripts/time.pm";
require "/home/tomoboy/Scripts/Include/time.pm";
####################################################################
# Extracting seismic waveforms for earthquakes reported by EOS
# Author   : Jiayuan Yao in 2019
# History  : 2019       Jiayuan Yao  Initial coding
#            04/28/2020 Jiayuan Yao  Enable first-P as reference
#
# Requirement : those commands should be contained in PATH variable
#   mseed2sac (https://github.com/iris-edu/mseed2sac/)
#   SAC       (http://ds.iris.edu/ds/nodes/dmc/forms/sac/)
#   distaz    (https://www.seis.sc.edu/software/distaz/)
#   TauP      (https://www.seis.sc.edu/taup/)
#
# Notes :
#   Change the PATH of time.pm in this and extract-sac.pl scripts.
####################################################################

# catalog
my $catalog = "catalog.dat";

# station location
#my $EOSsta  = "../station/MMEOS-coord.dat";
my $EOSsta  = "../station/nodes/N1EOS-coord.dat";

# miniseed directory (full path)
my $EOSAR   = "/run/media/tomoboy/4T-YAO1/EOS-Myanmar/mseed";

# data output directory
my $wf_dir  = "waveform";

# perl script to calculate traveltime (full path)
my $cal_time = "/run/media/tomoboy/4T-YAO1/EOS-Myanmar/scripts/CalTravelTime.pl";

# time window
#my $start = -60*60;
#my $end   = 120*60;
my $start    = -50; # time in second before the reference time
my $end      = 150; # time in second after the reference time

my $ref_flag = 1;   # ref_flag : 1 -->> reference is origin time
                    #            0 -->> reference is first P

# band codes
# H : broadband   L : long-period   E : extremely short-period (nodes)
#my $band = "H";      # broadband
#my $band = "H_E";   # broadband and nodes
my $band = "H_E_L"; # long-period and nodes


## make data output directory
`rm -rf $wf_dir` if (-d $wf_dir);
`mkdir $wf_dir`;


=pod
## read stations
open(STA, "< $EOSsta") || die "Error in opening $EOSsta.\n";


## make data output directory
`rm -rf $wf_dir` if (-d $wf_dir);
`mkdir $wf_dir`;


=pod
## read stations
open(STA, "< $EOSsta") || die "Error in opening $EOSsta.\n";
my @stas = <STA>; close(STA); chomp @stas;

my %sta_coords;
for (my $i = 0; $i < @stas; $i++) {
    my ($net, $sta, $stla, $stlo, $stel) = split " ", $stas[$i];
    $sta_coords{"${net}_${sta}"} = "${stla}_${stlo}_${stel}";
}
my @stations = sort keys %sta_coords;
=cut


## reading events
open(IN, "< $catalog") || die "Error in opening $catalog.\n";
my @eves = <IN>; close(IN); chomp @eves;


for (my $i = 0; $i < @eves; $i++) {
	next if (substr($eves[$i], 0, 1) eq "#");

    ## event parameters
	my ($origin0, $evla, $evlo, $evdp, $evmg) = split " ", $eves[$i];

    ## origin time
=pod
    my ($date, $time)         = split "T", $origin0;
    my ($year, $mon, $day)    = split "-", $date;
    my ($hour, $min, $second) = split ":", $time;
    my ($sec, $msec)          = split /\./, $second;
    my $origin = "${year}${mon}${day}${hour}${min}${sec}${msec}";
        print STDERR "Extracting mseed for #$year $mon $day ($yday) $hour $min $sec $msec#\n";
=cut
    my($year, $mon, $day, $hour, $min, $sec, $msec) = split " ", &OriginFormat($origin0);
    my $origin = "${year}${mon}${day}${hour}${min}${sec}${msec}";
    my $yday   = &time::CalDOY($origin);
        print STDERR "\n\nEvent $i: $year $mon $day ($yday) $hour $min $sec $msec\n";

=pod
    ## start time
    my $start_time = &time::Get_New_Time($origin, $start);
    my $yday_start = &time::CalDOY($start_time);
    my ($year_start, $mon_start, $day_start, $hour_start) = split " ", &time::Get_Head($start_time);
    #print STDERR "$origin\n$start_time\n";

    ## end time
    my $end_time = &time::Get_New_Time($origin, $end);
    my $yday_end = &time::CalDOY($end_time);
    my ($year_end, $mon_end, $day_end, $hour_end) = split " ", &time::Get_Head($end_time);
    #print STDERR "$origin\n$end_time\n";

    ## data is located at different files
    my @years = ($year_start, $year_end);
    my @ydays = ($yday_start, $yday_end);
    my @hours = ($hour_start);
       @hours = ($hour_start, $hour_end) if ($hour_start != $hour_end);
    for (my $j = 0; $j < @hours; $j++) {
        print STDERR "mseeds: #Year $years[$j]  Day $ydays[$j] $hours[$j]#\n";
    }
=cut

    ## event directory
    my $ev_dir = "$wf_dir/$origin";
   `mkdir $ev_dir` if (! (-d $ev_dir) );
#    chdir $ev_dir;

=pod
    ## extract sac files from mseed
    for (my $j = 0; $j < @stations; $j++) {
        my ($net, $sta) = split "_", $stations[$j];
        my ($stla, $stlo, $stel) = split "_", $sta_coords{$stations[$j]};
            #print STDERR "$stla $stlo $stel $net $sta\n";

        ## find mseed files
        my @mseeds;
        for (my $k = 0; $k < @hours; $k++) {
            ## data directory in EOS array
            my $data_dir = "$EOSAR/$years[$k]/$net/$sta";
            my @chn_dirs = glob "$data_dir/*.D"; chomp @chn_dirs;

            for (my $kk = 0; $kk < @chn_dirs; $kk++) {
                my $data_dir   = "$chn_dirs[$kk]/$ydays[$k]";
                my @mseeds_tmp = glob "$data_dir/${net}.${sta}.*.$years[$k].$ydays[$k].$hours[$k].*.mseed";
                push @mseeds, @mseeds_tmp;
            }
        }

        ## extract sac files from mseed
        if (@mseeds == 0) {
            print STDERR "No data for $origin $yday $net $sta\n";
            next;
        }
        for (my $k = 0; $k < @mseeds; $k++) {
            `mseed2sac $mseeds[$k]`;
        }

    } # for j

    chdir "\.\./\.\./";
=cut


    ## extract sac files from miniseed
    print STDERR "\n###############################\na. Extract sac files from miniseed\n";
    `perl extract-sac.pl $ev_dir $start $end $origin $evla $evlo $evdp $ref_flag $cal_time $EOSsta $EOSAR $band`;

    ## merge data
    print STDERR "\n###############################\nb. Merge Sac Files\n";
    `perl Merge.pl $ev_dir`;

    # rename seismic waveforms
    print STDERR "\n###############################\nc. Rename Sac Files\n";
    `perl rename.pl $ev_dir`;

    # write event information
    print STDERR "\n###############################\nd. Write Event Information\n";
    `perl WriteEvInfo.pl $ev_dir $year $yday $hour $min $sec $msec $evla $evlo $evdp $evmg`;

#    print STDERR "Cut Seismic Waveforms\n\n";
#    `perl CutWF.pl $ev_dir $start $end`;

    # write station information
    print STDERR "\n###############################\ne. Write Station Information\n";
    `perl WriteStaInfo.pl $ev_dir $EOSsta`;

    # cut seismic waveforms to the right time window
    print STDERR "\n###############################\nf. Cut Seismic Waveforms\n";
    `perl CutWF.pl $ev_dir $start $end $origin $ref_flag $cal_time`;

    # remove empty event
    `rmdir --ignore-fail-on-non-empty $ev_dir`;
}



#####################
### subroutines #####
#####################

# change the format of origin
# input  : e.g., 2020-04-19T20:39:05.984
# output : e.g., 20200419203905984
sub OriginFormat {
    my ($origin0) = @_;

    my ($date, $time)         = split "T", $origin0;
    my ($year, $mon, $day)    = split "-", $date;
    my ($hour, $min, $second) = split ":", $time;
    my ($sec, $msec)          = split /\./, $second;

    return "$year $mon $day $hour $min $sec $msec";
}


=pod
### Calculate Day of Dear
sub CalDOY {
    my ($origin) = @_;

    my ($wday, $yday, undef) = split " ", &time::CalDay($origin);
    if ($yday < 10) {
        $yday = "00${yday}"; }
    elsif ($yday < 100) {
        $yday = "0${yday}";
    }

    return "$yday";
}
=cut

