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

for IDX in 1 2; do
    find $(pwd) -name "H${IDX}.fasta" > H${IDX}.lst
    ./peregrine.sh H${IDX}.lst H${IDX}-asm
    ln -sf H${IDX}-asm/p_ctg_cns.fa contigs.H${IDX}.fasta
done
