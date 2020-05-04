#!/usr/bin/env perl
use strict;
use warnings;
use IPC::Cmd qw[can_run run];

if(not defined(can_run("samtools"))){
	print STDERR "ERROR\tsamtools is not in your \$PATH\n";
	exit 1;
}

open (BAM,"samtools view $ARGV[0]|") or die "Could not open " . $ARGV[0] . "for reading!\n";

my %hits;

while (my $line = <BAM>){
	chomp $line;
	my @bam = split(/\t/,$line);
	my $genome = $bam[2];
	if($genome eq "*"){
		$hits{$bam[0]} = "No_hit";
	}
	else{
		$genome =~ s/_[0-9]+$//;
		if(exists($hits{$bam[0]})){
			$hits{$bam[0]} = $hits{$bam[0]} . "," . $genome;
		}
		else{
			$hits{$bam[0]} = $genome;
		}
	}
}

close BAM;

my %result;

foreach(keys(%hits)){
	print STDERR $_ . "\t" . $hits{$_} . "\n";
	if($hits{$_} eq "No_hit"){
		if(exists($result{"No_hit\t0\t0"})){
			$result{"No_hit\t0\t0"} = $result{"No_hit\t0\t0"} + 1;
		}
		else{
			$result{"No_hit\t0\t0"} = 1;
		}
	}
	else{
		my @genomes = split(",",$hits{$_});
		my %geno;
		for(my $i = 0; $i < scalar(@genomes); $i++){
			if(exists($geno{$genomes[$i]})){
				$geno{$genomes[$i]} = $geno{$genomes[$i]} + 1;
			}
			else{
				$geno{$genomes[$i]} = 1;
			}
		}
		my $multiple_genomes = 0;
		if(scalar(keys(%geno)) > 1){
			$multiple_genomes = 1;
		}
		
		my $multiple_hits = 0;
		foreach(values(%geno)){
			if($_ > 1){
				$multiple_hits = 1;
			}
		}
		foreach(keys(%geno)){
			if(exists($result{$_ . "\t" . $multiple_hits . "\t" . $multiple_genomes})){
				$result{$_ . "\t" . $multiple_hits . "\t" . $multiple_genomes} = $result{$_ . "\t" . $multiple_hits . "\t" . $multiple_genomes} + 1;
			}
			else{
				$result{$_ . "\t" . $multiple_hits . "\t" . $multiple_genomes} = 1;
			}
		}
	}
}

my %dbs;

foreach(keys(%result)){
	my $database = (split /\t/,$_)[0];
	$dbs{$database} = "";
}

my @databases = sort(keys(%dbs));

print "Database\t" . join("\t",@databases) . "\n";


my %combinations = ("\t0\t0" => "One_hit_one_genome","\t1\t0" => "Multiple_hits_one_genome","\t0\t1" => "One_hit_multiple_genomes","\t1\t1" => "Multiple_hits_multiple_genomes");
my @combinations_keys = sort(keys(%combinations));
for(my $c = 0; $c < scalar(@combinations_keys); $c++){
	my $values = "";
	my $percent = "";
	for(my $i = 0; $i < scalar(@databases); $i++){
		if(exists($result{$databases[$i] . $combinations_keys[$c]})){
			$values = $values . "\t" . $result{$databases[$i] . $combinations_keys[$c]};
			my $p = ($result{$databases[$i] . $combinations_keys[$c]} / scalar(keys(%hits))) * 100;
			$percent = $percent . "\t" . $p;
		}
		else{
			$values = $values . "\t0";
			$percent = $percent . "\t0";
		}
	}
	print "#" . $combinations{$combinations_keys[$c]} . $values . "\n";
	print "%" . $combinations{$combinations_keys[$c]} . $percent . "\n";
}

exit;
