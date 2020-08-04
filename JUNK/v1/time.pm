package time;

# calculate date & time after duration seconds
sub Get_New_Time {
	use Time::Local;
	my ($date, $duration) = @_;

    my $precision = 5;

	# time difference in second w.r.t. 1970/01/01 00:00
	my ($year, $mon, $day, $hour, $min, $sec, $msec) = split " ", &Get_Head($date);
	$mon -= 1;
    my $time = timegm($sec, $min, $hour, $day, $mon, $year);

    # new time difference
    my $msec_length  = length($msec);
    my $msec_base    = 10**($msec_length);
	my $msec_sec     = $msec / $msec_base;
    #print STDERR "$msec_length $msec_base $msec_sec\n";

	$duration = sprintf("%.${precision}f", $duration);
	my $time_new     = $time + $msec_sec + $duration;
	my $time_new_int = int($time_new);
	my $msec_new     = $time_new - $time_new_int;

    # new msec
	$msec_new  = sprintf("%.${precision}f", $msec_new);
	$msec_new  = int($msec_new * $msec_base);

    # Add 0
    my $length0 = length($msec_new);
    my $zero_num= $msec_length - $length0;
    $zero_num = 0 if ($zero_num <= 0);
    $msec_new = "0"x$zero_num.$msec_new;

    # new time
	my ($wday, $yday, $isdast);
	($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdast) = gmtime($time_new_int);

    # special process of month and day
    $year += 1900;
    $mon  += 1;

    # add 0
    $mon  = "0$mon"  if ($mon  < 10);
    $day  = "0$day"  if ($day  < 10);
    $hour = "0$hour" if ($hour < 10);
    $min  = "0$min"  if ($min  < 10);
    $sec  = "0$sec"  if ($sec  < 10);

	my $new_date = "${year}${mon}${day}${hour}${min}${sec}${msec_new}";
	return $new_date;

}



# Format day of year
sub CalDOY {
    my ($origin) = @_;

    my ($wday, $yday, undef) = split " ", &CalDay($origin);
    if ($yday < 10) {
        $yday = "00${yday}"; }
    elsif ($yday < 100) {
        $yday = "0${yday}";
    }

    return "$yday";
}



# calculate day of year
# input: event origin time
# output: week of day, day of year, isdast
sub CalDay {
	use Time::Local;
	my ($date) = @_;

	my ($year, $mon, $day, $hour, $min, $sec, $msec) = split " ", &Get_Head($date);

	# time difference in second w.r.t. 1970/01/01 00:00
	$mon -= 1;
    my $time = timegm($sec, $min, $hour, $day, $mon, $year);

    # Day of week (Sun=0, Mon=1...Sat=6) and Day of year (0,1,2...)
	my ($wday, $yday, $isdast);
	($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdast) = gmtime($time);

    # special process
    $year += 1900;
    $mon  += 1;
    $yday += 1;
    #print STDERR "$year $mon $day $hour $min $sec\n";

    return "$wday $yday $isdast";
}



# get year month day hour min sec
# input: event origin time
# output
#	     year month day hour min sec msec
sub Get_Head {
    my ($head) = @_;

    my $year   = substr($head, 0, 4);
    my $mon    = substr($head, 4, 2);
    my $day    = substr($head, 6, 2);
    my $hour   = substr($head, 8, 2);
    my $min    = substr($head, 10, 2);
    my $sec    = substr($head, 12, 2);
    my $msec   = substr($head, 14);

    return "$year $mon $day $hour $min $sec $msec";
}


1;

