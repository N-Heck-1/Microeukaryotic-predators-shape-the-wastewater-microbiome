#!/bin/bash
#prefetches from SRA by accession stored in textfile and by number of accession in that file.
#takes two arguments: the line number of the first and the last accession in that file to prefetch.

#make sure prefetch is working:
cd ~/
export PATH=$PATH:$PWD/sratoolkit.2.11.2-ubuntu64/bin
cd ~/WORKING_DIR/Nils/
if [ $(which prefetch | wc -l) -eq 1 ]
then


#go through all accession
i=1
for accession in $(cat sra_accessions.txt)
do

	#look only at selected accessions
	if [ $i -ge $1 ] && [ $i -le $2 ]
	then
		echo looking at $accession
		#check memory of the two drives
		percenttbdrivefill=$(df | grep 'sdc1' | awk '{print $5}' | sed 's/%//')
		percentwddrivefill=$(df | grep 'sda1' | awk '{print $5}' | sed 's/%//')
		
		if [ $percentwddrivefill -le 90 ]
		then
		#the prefetch command
			prefetch $accession &
			wait
			echo prefetched $accession
			
			#try to move the sra file to the terabite drive
			if [ $percenttbdrivefill -le 99 ]
			then
				mv prefetch_output/sra/"$accession".sra /media/1tbssd/Nils/sra &
				wait
				echo moved $accession
			fi
		fi
	fi
#look at next accession
let "i=i+1"
done
fi