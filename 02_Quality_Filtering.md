# Data Access

Making use of the prefetched data and the [sra_getter.sh script](bash/sra_getter.sh), as described [here](01_Data_Access.md).



## Performing quality checks

The script used for this, [quality_controller.sh](bash/quality_controller.sh), takes two arguments, constititing the first and last accession in the list to be prefetched, same as with prefetching. It performs [FastQC](https://github.com/s-andrews/FastQC) quality control on each fastq file loaded, and removes those large files afterwards, a necessity when working on a small working directory drive.

```console
user@server:~$ bash quality_controller.sh 1 106
looking at SRR1427728
...
```


```sh
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
```

The produced quality control files were then used to determine filter parameters for trimming.

## Trimming and screening parameters

To better determine which parameters to use for trimming with [TrimGalore](https://github.com/FelixKrueger/TrimGalore/tree/0.6.7), we wanted to examine the properties of the contigs that would later be produced (using [mothur](https://doi.org/10.1128/AEM.01541-09)) from these trimmed sequences. For that, the following R script [screeningtester_graphics.R](R/screeningtester_graphics.R) was used, which plots four histograms of a contigs.report file as produced by mothur. These display overall contig length, overlap length, number of mismatches and number of a,biguities for one sample. Using the outputs of both this and the previous step with fastqc, parameters for TrimGalore and the later contig screening with mothur were arrived at.
It is called from the command line like this:
```console
user@server:~$ R --quiet --vanilla -f screeningtester_graphics.R --args SRR1427728_1_val
```

```r
#a script to visualize parameters of the contigs created from forward and reverse fastqs for one sample.
#called as R --quiet --vanilla -f screeningtester_graphics.R --args "$accession"_1_val_1
#or R --quiet --vanilla -f screeningtester_graphics.R --args "$accession"_1
filename <- commandArgs(trailingOnly = TRUE) 
mytable <- read.table(paste0(filename,".contigs.report"),header=T)
#plotting four histograms: contig length, oveerlap length, number of mismatches and number of ambiguities.
#each has 50 braks, meaning numbre of distinct columns in the histogram to be plotted.
Length_hist <- hist(mytable$Length, plot=F, breaks=50)
Overlap_hist <- hist(mytable$Overlap_Length, plot=F, breaks=50)
Mismatch_hist <- hist(mytable$MisMatches, plot=F, breaks=50)
Ambig_hist <- hist(mytable$Num_Ns, plot=F, breaks=50)

#writing into pdf with set x ranges (may need modification to your needs)
pdf(paste0(filename,"_hist.pdf"))
plot(Length_hist,xaxt="n")
xtick<-seq(0, 400, by=5)
axis(side=1, at=xtick)

plot(Overlap_hist,xaxt="n")
xtick<-seq(0, 400, by=2)
axis(side=1, at=xtick)

plot(Mismatch_hist,xaxt="n")
xtick<-seq(0, 100, by=1)
axis(side=1, at=xtick)

plot(Ambig_hist,xaxt="n")
xtick<-seq(0, 100, by=1)
axis(side=1, at=xtick)

dev.off()
```

A wrapper script ([contig_histogrammer.sh](bash/contig_histogrammer.sh)) in bash was produced, which loops, as previous scripts, though the acession list, applies this R script as well as allowing an option to either trim or not trim fastqs before making contigs.

```console
user@server:~$ bash contig_histogrammer.sh 1 106 trim
looking at SRR1427728
...
```

```sh
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

```
