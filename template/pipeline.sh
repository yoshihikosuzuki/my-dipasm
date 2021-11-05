#!/bin/bash
#SBATCH -J dipasm
#SBATCH -o dipasm.log
#SBATCH -p compute
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 1
#SBATCH --mem=1G
#SBATCH -t 72:00:00
shopt -s expand_aliases && source ~/.bashrc && set -e || exit 1

cd 1-merged-asm/ &&
    MERGED_ASM=$(sbatch peregrine.sh | cut -f 4 -d' ') &&
    cd ..
cd 2-alignment-and-vc/ &&
    cd hifi/ &&
        HIFI=$(sbatch -d afterany:${MERGED_ASM} hifi.sh | cut -f 4 -d' ') &&
        cd ..
    cd hic/ &&
        HIC=$(sbatch -d afterany:${MERGED_ASM} hic.sh | cut -f 4 -d' ') &&
        cd ..
    cd ..
cd 3-phasing/ &&
    PHASE=$(sbatch -d afterany:${HIFI},${HIC} phase.sh | cut -f 4 -d' ') &&
    cd ..
# cd 4-phased-asm/ &&
#     PHASED_ASM=$(sbatch -d afterany:${PHASE} asm.sh | cut -f 4 -d' ') &&
#     cd ..
cd 4-phased-asm-scratch/ &&
    PHASED_ASM=$(sbatch -d afterany:${PHASE} asm.sh | cut -f 4 -d' ') &&
    cd ..

srun -p compute -c 1 --mem 1G -t 1:00:00 -d afterany:${PHASED_ASM} --wait=0 sleep 1s
