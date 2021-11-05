#!/bin/bash
#SBATCH -J peregrine
#SBATCH -o peregrine.log
#SBATCH -p compute
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 128
#SBATCH --mem=500G
#SBATCH -t 24:00:00
shopt -s expand_aliases && source ~/.bashrc && set -e || exit 1
source ../config.sh

ml samtools bwa Other/peregrine

OUT_DIR=asm
N_THREAD_SETTING="${N_THREADS} ${N_THREADS} ${N_THREADS} ${N_THREADS} ${N_THREADS} ${N_THREADS} ${N_THREADS} ${N_THREADS} ${N_THREADS}"

find ${PBPATH}/ -name "*.fastq" | sort >reads.fofn
peregrine reads.fofn ${N_THREAD_SETTING} --with-consensus --shimmer-r 3 --best_n_ovlp 8 --output ${OUT_DIR}
ln -sf ${OUT_DIR}/p_ctg_cns.fa ${REF}
samtools faidx ${REF}
bwa index ${REF}
