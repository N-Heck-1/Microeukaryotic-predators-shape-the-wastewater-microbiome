# Data Access

Following [Herold et al. (2020)](https://www.nature.com/articles/s41467-020-19006-2), their Meta-omics dataset was made available via NCBI BioProject under accession [PRJNA230567](https://www.ncbi.nlm.nih.gov/bioproject/?term=PRJNA230567). This includes the metagenomic and metatranscriptomic read data in the fastq format, which were available via the [SRA](https://www.ncbi.nlm.nih.gov/sra?LinkName=bioproject_sra_all&from_uid=230567).
In the initial steps of this process, both metagenomic and metatranscriptomic data will be handled, but only metatranscriptomic data was ultimately utilized in the study.

## Prefetching

Making use of the [SRA-toolkit](https://github.com/ncbi/sra-tools/wiki), and a list of all relevant individual accessions ([sra_accessions.txt](original_data/sra_accessions.txt)), all files were prefetched, making it quicker and easier to repeatedly load and remove the fastq files, which was necessary when deciding on filter parameters to conserve server hard drive space. Further, to keep the working directory as empty as possible, the prefetch outputs were stored in a storage drive (called terabyte drive in the code).
It can also only be called for some or even a single accession, as this script, [prefetcher.sh](bash/prefetcher.sh), takes two arguments, constititing the first and last accession in the list to be prefetched.
```console
user@server:~$ bash prefetcher.sh 1 106
looking at SRR1427728
prefetched SRR1427728
moved SRR1427728
looking at SRR1427729
...
```

```sh
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
		mv prefetch_output/sra/"$accession".sra /media/1tbssd/sra &
		wait
		echo moved $accession
	fi
#look at next accession
let "i=i+1"
done
```

## Keeping the working directory clear

A second script was also involved in the moving of prefetch output files, as they would still be needed in the working directory drive for loading of fastq files, e.g. for quality control. Therefore, this script, called [sra_getter.sh](bash/sra_getter.sh), would later be called to retrieve the prefetched .sra file for a single accession number, and output if the file was indeed retrieved from the terabyte drive, or if it was found in the working directory. With that information, the file could later be moved to its previous position by calling the "putback" option of the script. A demonstration from the command line is shown below, using the script to retrieve the prefetched file, load the fastq file with the SRA-toolkit, and then removing the prefetched file again.

```console
user@server:~$ bash sra_getter.sh SRR1427728 get > tempfile.txt
user@server:~$ fasterq-dump -S SRR1427728
user@server:~$ bash sra_getter.sh SRR1427728 putback $(cat tempfile.txt)
user@server:~$ rm tempfile.txt
```

**Please note:** This process is overcomplicated and not necessary if your hard drive space is less limited. It is also not necessary if you directly go ahead with the whole pipeline for one sample, instead of first loading all samples to e.g. tune quality filters. Further, copying the prefetched fules instead of moving them would work just as well. This step is only presented here to document the process as it was performed for the study.

```sh
#!/bin/bash
#a script to move the sra file called by its accession in the first argument back where it can be used. in case it was stored on the 1TB drive, that is echoed.
#the second argument is either "get" or "putback". get outputs a string, which can be received as third argument in putback mode to put it back to its original saving position.

accession=$1
operation=$2
knownlocation=$3
if [ $operation = "get" ]
then
	if [ $(ls /media/1tbssd/sra/ | grep "$accession"\.sra | wc -l) -gt 0 ]
	then
		mv /media/1tbssd/sra/"$accession".sra ./prefetch_output/sra/ &
		wait
		echo tbd
	else
		echo wdd
	fi
fi

if [ $operation = "putback" ] && [ $knownlocation = "tbd" ]
then
	mv ./prefetch_output/sra/"$accession".sra /media/1tbssd/sra/ &
	wait
fi
```
