#!/usr/bin/perl
#
####################################################################
# Extracting seismic waveforms for earthquakes reported by EOS
#
# History
#   2019        Jiayuan Yao  Initial coding
#   04/28/2020  Jiayuan Yao  First-P can also be the reference
#   04/29/2020  Jiayuan Yao  Include long- and short-period bands,
#                            any length data can be extracted now
#
# Requirement (those commands should be in the environment variable)
#   mseed2sac (https://github.com/iris-edu/mseed2sac/)
#   SAC       (http://ds.iris.edu/ds/nodes/dmc/forms/sac/)
#   distaz    (https://www.seis.sc.edu/software/distaz/)
#   TauP      (https://www.seis.sc.edu/taup/)
####################################################################
use strict;
use warnings;
use File::Basename;
require "./time.pm";

# default values
my $catalog  = "../catalog/catalog.dat";      # catalog
my $EOSsta   = "../station/MMEOS-coord.dat";  # broadband stations
#my $EOSsta  = "../station/N1EOS-coord.dat";  # node stations
my $mseed_dir= "/run/media/tomoboy/4T-YAO1/EOS-Myanmar/mseed";
                                              # miniseed directory (full path)
my $sac_dir  = "../waveform";                 # sac data directory

my $ref_flag = 1;        # reference time flag
                         # 0=origin time; 1=first P; 2=first S
my $start    = -50;      # time in second before reference time
my $end      = 150;      # time in second after  reference time

my $band     = "H";      # only broadband
#my $band    = "H_E";    # both broadband and nodes
#my $band    = "H_E_L";  # broadband, nodes, and long-period
                         # H: broadband  L: long-period  E: extremely short-period (nodes)

# command line options
@ARGV > 1 or die "Usage: ExtractWaveform.pl -Ccatalog -SEOSsta -Mmseed_dir -Osac_dir -Rref_flag -Tstart,end -Bband1[,band2[,band3[,...]]]
-C: catalog
-S: EOS station locations
-M: miniseed data directory (must be full path, e.g., /home/core-man/mseed)
-O: output sac data directory
-R: reference time flag; 0=origin time; 1=first P; 2=first S
-T: time in second before (start) and after (end) the reference
-B: station band; E=extremely short-period, H=broadband, L=long-period

Examples
* To extract broadband data with -50 s before and 150 s after first P, use
./ExtractWaveform.pl -C../catalog/catalog.dat -S../station/MMEOS-coord.dat -Mmseed_dir -O../waveform -R1 -T-50,150 -BH
* To extract both broadband and extremely short-period, use
./ExtractWaveform.pl -C../catalog/catalog.dat -S../station/MMEOS-coord.dat -Mmseed_dir -O../waveform -R1 -T-50,150 -BH,E\n";


foreach (grep(/^-/,@ARGV)) {
   my $opt   = substr($_,1,1);
   my @value = split(/,/,substr($_,2));
   if ($opt eq "C") {
     $catalog = $value[0];
   } elsif ($opt eq "S") {
     $EOSsta = $value[0];
   } elsif ($opt eq "M") {
     $mseed_dir = $value[0];
   } elsif ($opt eq "O") {
     $sac_dir = $value[0];
   } elsif ($opt eq "R") {
     $ref_flag = $value[0];
   } elsif ($opt eq "T") {
     $start = $value[0];
     $end   = $value[1];
   } elsif ($opt eq "B") {
     $band = join("_", @value);
   } else {
     print STDERR "Error **** Wrong options\n";
     exit(0);
   }
}



######## begin to extract seismic data ###########

# make output directory
`rm -rf $sac_dir` if (-d $sac_dir);
`mkdir $sac_dir`;


# reading events
open(IN, "< $catalog") || die "Error in opening $catalog.\n";
my @eves = <IN>; close(IN); chomp @eves;


# loop event
for (my $i = 0; $i < @eves; $i++) {
	next if (substr($eves[$i], 0, 1) eq "#");

    # find event parameters
	my ($origin0, $evla, $evlo, $evdp, $evmg) = split " ", $eves[$i];

    # find origin time
    my($year, $mon, $day, $hour, $min, $sec, $msec) = split " ", &OriginFormat($origin0);
    my $origin = "${year}${mon}${day}${hour}${min}${sec}${msec}";
    my $yday   = &time::CalDOY($origin);

    # make event directory
    my $ev_dir = "$sac_dir/$origin";
   `mkdir $ev_dir` if (! (-d $ev_dir) );


    print STDERR "\n\n######################################\n";
    print STDERR "Event $i: $year $mon $day ($yday) $hour $min $sec $msec\n";

    # extract sac files from miniseed
    `perl extract-sac.pl $ev_dir $start $end $origin $evla $evlo $evdp $ref_flag $EOSsta $mseed_dir $band`;

    # merge data at the same station
    `perl merge.pl $ev_dir`;

    # rename seismic waveforms
    `perl rename.pl $ev_dir`;

    # write event information
    `perl WriteEvInfo.pl $ev_dir $year $yday $hour $min $sec $msec $evla $evlo $evdp $evmg`;

    # write station information
    `perl WriteStaInfo.pl $ev_dir $EOSsta`;

    # cut seismic waveforms to the right time window
    `perl CutWF.pl $ev_dir $start $end $origin $ref_flag`;

    # remove empty event
    `rmdir --ignore-fail-on-non-empty $ev_dir`;
}



############ subroutines ##############

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

