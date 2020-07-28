#/bin/bash
# extract seismic data at EOS, using EOS.data-scripts in https://github.com/core-man/EOS.data-scripts
# copy this script into EOS.data-scripts/scripts, and run it

# input
catalog=/home/tomoboy/Desktop/RF.Myanmar/catalog/events/ComCat-20160101-20200728-tele.dat
station=../station/MMEOS-coord.dat
mseedir=/run/media/tomoboy/4T-YAO1/EOS-Myanmar/mseed
sacdir=/run/media/tomoboy/4T-YAO7/Myanmar/DATA/ENZ-origin

./ExtractWaveform.pl -C$catalog -S$station -M$mseedir -O$sacdir -Eak135 -T-50,150 -BH

