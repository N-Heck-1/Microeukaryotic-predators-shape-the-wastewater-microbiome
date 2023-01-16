#!/bin/bash
#makes fastqs from SRA by accession stored in textfile and by number of accession in that file.
#takes two arguments: the line number of the first
#and the last accession in that file to make fastqs from.
#it then performs fastqc quality control and deletes the fastqs again.

#go through all accessions
i=1
for accession in $(cat sra_accessions.txt)
do
	#look only at selected accessions
	if [ $i -ge $1 ] && [ $i -le $2 ]
	then
		echo looking at $accession
		bash sra_getter.sh $accession get > "$accession"_tempfile.txt
		fasterq-dump -S $accession
		bash sra_getter.sh $accession putback $(cat "$accession"_tempfile.txt)
		rm "$accession"_tempfile.txt
		fastqc "$accession"* -q &
		wait
		rm "$accession"*.fastq
	fi
#look at next accession
let "i=i+1"

done
