#!/usr/bin/env perl
use strict;
use warnings;

my %ids;

open (ID,$ARGV[0]) or die "Could not open " . $ARGV[0] . "for reading!\n";

while (my $line = <ID>){
	chomp $line;
	$ids{$line} = "";
}

close ID;

open (PAF,$ARGV[1]) or die "Could not open " . $ARGV[1] . "for reading!\n";

my %hits;

while (my $line = <PAF>){
	chomp $line;
	my @paf = split(/\t/,$line);
	my $genome = $paf[5];
	$genome =~ s/_[0-9]+$//;
	if(exists($hits{$paf[0]})){
		$hits{$paf[0]} = $hits{$paf[0]} . "," . $genome;
	}
	else{
		$hits{$paf[0]} = $genome;
	}
}

close PAF;

my $no_hit = 0;
my %result;

foreach(keys(%ids)){
	if(exists($hits{$_})){
		print STDERR $_ . "\t" . $hits{$_} . "\n";
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
	else{
		print STDERR $_ , "\tNo_hit\n";
		if(exists($result{"No_hit\t0\t0"})){
			$result{"No_hit\t0\t0"} = $result{"No_hit\t0\t0"} + 1;
		}
		else{
			$result{"No_hit\t0\t0"} = 1;
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
			my $p = ($result{$databases[$i] . $combinations_keys[$c]} / scalar(keys(%ids))) * 100;
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
