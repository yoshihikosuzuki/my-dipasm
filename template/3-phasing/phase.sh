#!/bin/bash
#SBATCH -J phase
#SBATCH -o phase.log
#SBATCH -p compute
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 128
#SBATCH --mem=500G
#SBATCH -t 24:00:00
shopt -s expand_aliases && source ~/.bashrc || exit 1
source ../config.sh

ml parallel HapCUT2/dipasm whatshap samtools htslib

HIC=../2-alignment-and-vc/hic/split
VCF=../2-alignment-and-vc/hifi/vcf
HIFI_SPLIT=../2-alignment-and-vc/hifi/split

SCAFFOLDS=$(cut -d$'\t' -f1 ${FAI})

# HapCUT2
parallel "extractHAIRS --bam $HIC/hic.{}.bam --hic 1 --VCF $VCF/hifi.{}.filtered.vcf --out hapcut2/hic.{}.frag --maxIS 30000000" ::: $SCAFFOLDS
parallel "HAPCUT2 --fragments hapcut2/hic.{}.frag --VCF $VCF/hifi.{}.filtered.vcf --output hapcut2/hic.{}.hap --hic 1" ::: $SCAFFOLDS
parallel "cut -d$'\t' -f1-11 hapcut2/hic.{}.hap > hapcut2/hic.{}.hap.cut" ::: $SCAFFOLDS
parallel "whatshap hapcut2vcf $VCF/hifi.{}.filtered.vcf hapcut2/hic.{}.hap.cut -o hapcut2/hic.{}.phased.vcf" ::: $SCAFFOLDS

# WhatsHap
# NOTE: can exit here by errors in contigs that do not have any mapped reads
parallel "whatshap phase --reference $REF $VCF/hifi.{}.filtered.vcf hapcut2/hic.{}.phased.vcf $HIFI_SPLIT/hifi.{}.bam -o whatshap/{}.phased.vcf" ::: $SCAFFOLDS
parallel "bgzip -c whatshap/{}.phased.vcf > whatshap/{}.phased.vcf.gz" ::: $SCAFFOLDS
parallel "tabix -p vcf whatshap/{}.phased.vcf.gz" ::: $SCAFFOLDS
parallel "whatshap haplotag --reference $REF whatshap/{}.phased.vcf.gz $HIFI_SPLIT/hifi.{}.bam -o haplotag/{}.haplotag.bam" ::: $SCAFFOLDS

parallel "samtools view haplotag/{}.haplotag.bam | grep 'HP:i:1' | awk '{print \">\"\$1\"\n\"\$10}' > haplotag/{}-SCAFF-H1.fasta" ::: $SCAFFOLDS
parallel "samtools view haplotag/{}.haplotag.bam | grep 'HP:i:2' | awk '{print \">\"\$1\"\n\"\$10}' > haplotag/{}-SCAFF-H2.fasta" ::: $SCAFFOLDS
parallel "samtools view haplotag/{}.haplotag.bam | grep -v 'HP:' | awk '{print \">\"\$1\"\n\"\$10}' > haplotag/{}-SCAFF-untagged.fasta" ::: $SCAFFOLDS

cat haplotag/*-H1.fasta haplotag/*-untagged.fasta > H1.fasta
cat haplotag/*-H2.fasta haplotag/*-untagged.fasta > H2.fasta
