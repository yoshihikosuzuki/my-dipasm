#!/bin/bash
shopt -s expand_aliases && source ~/.bashrc && set -e || exit 1
source ../../config.sh

ml deepvariant

SEQ=$1
PAT=$(echo ${SEQ} | sed 's/\([^\\]\);/\1\\\\;/g' | sed 's/\([^\\]\)=/\1\\\\=/g')
TMP_DIR=${SEQ}-tmp

mkdir -p ${TMP_DIR}
run_deepvariant \
    --model_type=PACBIO \
    --ref=${REF} \
    --reads="split/hifi.${PAT}.bam" \
    --output_vcf="vcf/hifi.${PAT}.vcf.gz" \
    --regions "${PAT}" \
    --intermediate_results_dir ${TMP_DIR} \
    --num_shards=${N_JOB_THREADS}
rm -rf ${TMP_DIR}
