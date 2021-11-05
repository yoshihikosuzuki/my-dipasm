#!/bin/bash
shopt -s expand_aliases && source ~/.bashrc && set -e || exit 1

ml Other/peregrine

READS_FOFN=$1
OUT_DIR=$2
N_THREAD=${N_JOB_THREADS}
N_THREAD_SETTING="${N_THREAD} ${N_THREAD} ${N_THREAD} ${N_THREAD} ${N_THREAD} ${N_THREAD} ${N_THREAD} ${N_THREAD} ${N_THREAD}"

peregrine ${READS_FOFN} ${N_THREAD_SETTING} --with-consensus --shimmer-r 3 --best_n_ovlp 8 --output ${OUT_DIR}
