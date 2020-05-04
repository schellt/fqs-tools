# FastQ Screen like tools

## Description
[FastQ Screen](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/) is a tool to detect possible contamination by mapping the reads to certain genomes or databases. With these scripts one can create a list containing each read ID and the corresponding hits to filter reads as well as a tabular overview to allow plotting in a FastQ Sreen like fashion.

## Preparation
The scripts are written to expect the name of the database part before and one or multiple digits after an underscore in each database sequence ID. For example, if you have two sequences of bacteria, one human and two viral sequences it should look like this:
```
$ grep ">" database.fasta
>bacteria_1
>bacteria_2
>human_1
>virus_1
>virus_1
```
Afterwards you can build the indices (if needed) and map the reads you want to screen. For short reads I recommend [`bwa mem`](https://github.com/lh3/bwa) and for long reads [`minimap2`](https://github.com/lh3/minimap2). Paired reads should be mapped separately in unpaired mode. Pairing information can be restored after filtering.

## Dependencies

`bam2fqs.pl` needs `samtools` in your `$PATH`.

## Usage

`bam2fqs.pl` and `paf2fqs.pl` print a tabular separated list (`fqs-id-list`) to `STDOUT` that contains the read ID and a comma separated list of database hits (with duplicates). This file can be used to filter for read IDs with certain hits or hit combinations.   
A tabular separated table (`fqs-table`) is printed to `STDERR` from `bam2fqs.pl` and `paf2fqs.pl` and to `STDOUT` by `ids2fqs.pl`. This table contains absolute and relative numbers of hits to the database parts in the FastQ Screen categories “One hit\one genome”, “Multiple hits\one genome”, “One hit\multiple genomes” and “Multiple hits\multiple genomes”. `ids2fqs.pl` can be used to combine multiple `fqs-id-list`s into one `fqs-table`.   
For `paf2fqs.pl` a list of all mapped read IDs is needed (`full-id-list`), since unmapped reads are not contained in `paf` format. The `full-id-list` must not contain the starting character of the format (e.g. `>` or `@`).
```
bam2fqs.pl <bam-file> > <fqs-id-list> 2> <fqs-table>

paf2fqs.pl <full-id-list> <paf-file> > <fqs-id-list> 2> <fqs-table>

ids2fqs.pl <fqs-id-list1> [<fqs-id-list2> ...] > <fqs-table>
```

## Plotting

Plotting can be done by removing the lines that should not be plotted (either absolute or relative numbers) and using this `R` code as template:

```R
x=read.table("fqs-table-prec",header=TRUE)
barplot(as.matrix(x[2:8]),col=c("blue","darkblue","red","darkred","blue"),ylim=c(0,100),las=2,ylab="% Mapped",xaxt="n",main="FastqScreen like contamination scan")
legend("topright",pch=c(15,15),col=c("blue","darkblue","red","darkred"),legend=c("One hit\\one genome","Multiple hits\\one genome","One hit\\multiple genomes","Multiple hits\\multiple genomes"))
dev.print("fqs-table-perc.pdf",device=pdf)
```

## Restore paired information

To restore paired information, create a list for forward and reverse reads that contain filtered IDs only first. Afterwards check, if both lists contain the ID.   
For example, to filter for unmapped reads only one can do:
```
awk '$2=="No_hit"' fsq-list1 > fsq-list1.f
awk '$2=="No_hit"' fsq-list2 > fsq-list2.f

cat fsq-list1.f fsq-list1.f | sort | uniq -c | awk '$1==1{print $2}' > unpaired1.ids
cat fsq-list1.f fsq-list2.f | sort | uniq -c | awk '$1==2{print $2}' > paired.ids
```
