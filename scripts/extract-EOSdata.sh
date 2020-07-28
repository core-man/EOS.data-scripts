#/bin/bash
# extract seismic data at EOS, using EOS.data-scripts in https://github.com/core-man/EOS.data-scripts

catalog=/home/core-man/catalog/catalog.dat
station=../station/MMEOS-coord.dat
mseedir=/run/media/core-man/4T/EOS-Myanmar/mseed
sacdir=/run/media/core-man/4T/EOS-Myanmar/sac

./ExtractWaveform.pl -C$catalog -S$station -M$mseedir -O$sacdir -Rttp -Eak135 -T-50,150 -BH

