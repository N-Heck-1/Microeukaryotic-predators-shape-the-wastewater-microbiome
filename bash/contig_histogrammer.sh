#!/bin/bash
#makes fastqs from SRA by accession stored in textfile and by number of accession in that file. then makes contigs with or without trimming, and histograms from that.
#takes three arguments: the line number of the first and the last accession in that file to make fastqs from; and "trim" or "notrim"


operation=$3

#make sure prefetch is working:
cd ~/
export PATH=$PATH:$PWD/sratoolkit.2.11.2-ubuntu64/bin
cd ~/WORKING_DIR/
if [ $(which prefetch | wc -l) -eq 1 ]
then
	#go through all accessions
	i=1
	for accession in $(cat sra_accessions.txt)
	do
	
		#look only at selected accessions
		if [ $i -ge $1 ] && [ $i -le $2 ]
		then
			echo looking at $accession
			#retrieve prefetched file
			bash sra_getter.sh $accession get > "$accession"_tempfile.txt
			#load fastqs
			fasterq-dump -S $accession
			bash sra_getter.sh $accession putback $(cat "$accession"_tempfile.txt)
			rm "$accession"_tempfile.txt
			if [ $operation = "trim" ]
			then
				#here different trimming parameters can be chosen for metagenomic or metatranscriptomic data
				a=$(grep $(echo $accession) accessions_with_some_info.txt | awk '{print $6}')
				if [ $a = METAGENOMIC ]
				then
					~/TrimGalore-0.6.7/trim_galore -j 6 -q 30 --paired --three_prime_clip_R1 10 --three_prime_clip_R2 10 --output_dir ~/WORKING_DIR/ ~/WORKING_DIR/"$accession"_1.fastq ~/WORKING_DIR/"$accession"_2.fastq
				fi
				if [ $a = METATRANSCRIPTOMIC ]
				then
					~/TrimGalore-0.6.7/trim_galore -j 6 -q 30 --paired --three_prime_clip_R1 10 --three_prime_clip_R2 10 --output_dir ~/WORKING_DIR/ ~/WORKING_DIR/"$accession"_1.fastq ~/WORKING_DIR/"$accession"_2.fastq
				fi
				rm "$accession"*.fastq
				#making contigs from trimmed data
				~/mothur_1_45_3/mothur "#set.dir(output=~/WORKING_DIR/);make.contigs(ffastq=~/WORKING_DIR/"$accession"_1_val_1.fq, rfastq=~/WORKING_DIR/"$accession"_2_val_2.fq, processors=6, checkorient=T);quit()"
				#plotting histograms of contig parameters
				R --quiet --vanilla -f screeningtester_graphics.R --args "$accession"_1_val_1
			else
				#making contigs directly from untrimmed fastqs
				~/mothur_1_45_3/mothur "#set.dir(output=~/WORKING_DIR/);make.contigs(ffastq=~/WORKING_DIR/"$accession"_1.fastq, rfastq=~/WORKING_DIR/"$accession"_2.fastq, processors=6, rename=T, checkorient=T);quit()"
				#plotting histograms of contig parameters
				R --quiet --vanilla -f screeningtester_graphics.R --args "$accession"_1
			fi
			#clearing the working directory
			rm "$accession"*contigs* mothur*logfile "$accession"*report* "$accession"*fq
		fi
	#look at next accession
	let "i=i+1"
	done
	
	#move output files into folders
	for i in $(ls SRR*.pdf)
	do
		a=$(grep $(echo $i | sed 's/_.*//') accessions_with_some_info.txt | awk '{print $6}')
		if [ $operation = "trim" ]
		then
			if [ $a = METAGENOMIC ]
			then
				mv $i ./histograms/trimming/metagenomics/$i
			fi
			if [ $a = METATRANSCRIPTOMIC ]
			then
				mv $i ./histograms/trimming/metatranscriptomics/$i
			fi
		else
			if [ $a = METAGENOMIC ]
			then
				mv $i ./histograms/untrimmed/metagenomics/$i
			fi
			if [ $a = METATRANSCRIPTOMIC ]
			then
				mv $i ./histograms/untrimmed/metatranscriptomics/$i
			fi
		fi
	done
fi
