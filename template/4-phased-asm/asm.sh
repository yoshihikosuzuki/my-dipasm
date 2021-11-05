#!/bin/bash
#SBATCH -J assemble
#SBATCH -o assemble.log
#SBATCH -p compute
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 128
#SBATCH --mem=500G
#SBATCH -t 24:00:00
shopt -s expand_aliases && source ~/.bashrc && set -e || exit 1
source ../config.sh

ml parallel

PBPATH=$(readlink -f ../3-phasing/haplotag/)
SCAFFOLDS=$(cut -d$'\t' -f1 ${FAI})

for IDX in 1 2; do
    parallel -j${N_JOB} "find $PBPATH/ -name \"{}-SCAFF-H${IDX}.fasta\" > asm/{}-SCAFF-H${IDX}.lst" ::: $SCAFFOLDS
    parallel -j${N_JOB} "find $PBPATH/ -name \"{}-SCAFF-untagged.fasta\" >> asm/{}-SCAFF-H${IDX}.lst" ::: $SCAFFOLDS
    parallel -j${N_JOB} "./peregrine.sh asm/{}-SCAFF-H${IDX}.lst asm/{}-SCAFF-H${IDX}" ::: $SCAFFOLDS
done

find . -name p_ctg_cns.fa | ./genfa.pl $SAMPLE
