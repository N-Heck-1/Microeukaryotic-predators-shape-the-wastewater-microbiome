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
