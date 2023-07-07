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
