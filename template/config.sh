#!/bin/bash

# Environment-specific commands
module purge
module use --append /apps/.modulefiles72
module use /apps/.bioinfo-ugrp-modulefiles81
module use /apps/unit/BioinfoUgrp/DebianMed/10.7/modulefiles


# User-specified variables
SAMPLE=asm


# Constants
ROOT=$(dirname ${BASH_SOURCE[0]})
HICPATH=$(readlink -f ${ROOT}/0-data/hic)
PBPATH=$(readlink -f ${ROOT}/0-data/hifi)
REF=contigs.fasta
FAI=${REF}.fai
N_THREADS=128
N_JOB=8
N_JOB_THREADS=16
