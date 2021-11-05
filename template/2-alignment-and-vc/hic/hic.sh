#!/bin/bash
#SBATCH -J hic
#SBATCH -o hic.log
#SBATCH -p compute
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 128
#SBATCH --mem=500G
#SBATCH -t 24:00:00
shopt -s expand_aliases && source ~/.bashrc && set -e || exit 1
source ../../config.sh

ml parallel bwa samtools HapCUT2/dipasm biobambam

SCAFFOLDS=$(cut -d$'\t' -f1 ${FAI})

for PAIR in 1 2; do
    ls ${HICPATH}/*_R${PAIR}_*.f*q | parallel -j${N_JOB} "split -l 8000000 {} ${HICPATH}/split${PAIR}/{/.}_"
    ls ${HICPATH}/split${PAIR}/ | parallel -j${N_JOB} "bwa mem -t ${N_JOB_THREADS} -R '@RG\tSM:$SAMPLE\tID:$SAMPLE' -B 8 -M $REF ${HICPATH}/split${PAIR}/{} | samtools sort -@${N_JOB_THREADS} -n -o chunks${PAIR}/{/.}.nsort.bam" >bwa.${PAIR}.log 2>&1
done

# For HiC_repair.py, manually change line:229, output str to 'wb', for compressed BAM output.
my_func() { echo HiC_repair.py -b1 $1 -b2 $2 -o repaired/${1##*/}.repaired.bam; }
export -f my_func
parallel --xapply my_func ::: chunks1/*.nsort.bam ::: chunks2/*.nsort.bam | parallel
samtools merge -f -@${N_THREADS} hic.repaired.bam repaired/*
samtools fixmate -@${N_THREADS} hic.repaired.bam - | samtools sort -@${N_THREADS} -o hic.fix.sort.bam
samtools index -@${N_THREADS} hic.fix.sort.bam
bammarkduplicates2 I=hic.fix.sort.bam O=hic.fix.sort.md.bam M=markdup.metrics markthreads=${N_THREADS} rmdup=1 index=1

parallel -j${N_JOB} "samtools view -@${N_JOB_THREADS} -b -o split/hic.{}.bam hic.fix.sort.md.bam {}" ::: ${SCAFFOLDS}
