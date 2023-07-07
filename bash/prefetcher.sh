#!/bin/bash
#prefetches from SRA by accession stored in textfile "sra_accessions.txt" and by number of accession in that file.
#takes two arguments: the line number of the first and the last accession in that file to prefetch.


#go through all accession
i=1
for accession in $(cat sra_accessions.txt)
do
	#look only at selected accessions
	if [ $i -ge $1 ] && [ $i -le $2 ]
	then
		echo looking at $accession
		#the prefetch command
		prefetch $accession &
		wait
		echo prefetched $accession
		#move the sra file to the terabyte drive
		mv ./prefetch_output/sra/"$accession".sra /media/1tbssd/sra &
		wait
		echo moved $accession
	fi
#look at next accession
let "i=i+1"
done
