#!/bin/bash
#SBATCH -J hifi
#SBATCH -o hifi.log
#SBATCH -p compute
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 128
#SBATCH --mem=500G
#SBATCH -t 48:00:00
shopt -s expand_aliases && source ~/.bashrc && set -e || exit 1
source ../../config.sh

ml parallel samtools winnowmap htslib

SCAFFOLDS=$(cut -d$'\t' -f1 ${FAI})

# Winnowmap
K=15
OUT_BAM=hifi.bam
OUT_MERYL=${REF%.*}.meryl
OUT_REP=${REF%.*}.rep
meryl count k=${K} output ${OUT_MERYL} ${REF}
meryl print greater-than distinct=0.9998 ${OUT_MERYL} >${OUT_REP}
winnowmap -W ${OUT_REP} -t${N_THREADS} -ax map-pb -R "@RG\tSM:$SAMPLE\tID:$SAMPLE" --eqx --secondary=no ${REF} ${PBPATH}/*.f*q |
    samtools sort -@${N_THREADS} -o ${OUT_BAM}
samtools index -@${N_THREADS} ${OUT_BAM}
parallel -j${N_JOB} "samtools view -@${N_JOB_THREADS} -b hifi.bam {} > split/hifi.{}.bam" ::: $SCAFFOLDS
parallel -j${N_JOB} "samtools index -@${N_JOB_THREADS} split/hifi.{}.bam" ::: $SCAFFOLDS

# Deepvariant
parallel -j${N_JOB} "./dv.sh {} > vcf/{}.log 2>&1" ::: $SCAFFOLDS
parallel -j${N_JOB} "bgzip -cd {} > {.}" ::: $(ls vcf/*.gz)
parallel -j${N_JOB} "grep -E '^#|0/0|1/1|0/1|1/0|0/2|2/0' {} > {.}.filtered.vcf" ::: $(ls vcf/*.vcf)
