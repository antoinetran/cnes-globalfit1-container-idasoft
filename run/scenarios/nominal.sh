#!/bin/sh

. ~/set_proxy.sh
sifFile=/work/SC/lisa/${USER}/cnes-lisa-globalfit1-idasoft-hpc.sif

# Default is 100000. Estimation time (depends on the ressources): default steps takes around a week. 10000 steps takes around 30min.
steps=100000
# select=Number of node
# ncpus=Number of Cpus per node for all processes
# mpiprocs=Number of Cpus per node allocated for MPI.
pbsRss="select=23:ncpus=40:mpiprocs=5:mem=50gb:os=rh7:generation=g2019"
# Number of OpenMP threads. The higher the lesser for walltime (better).
OMP_NUM_THREADS=5
# Number of chains for tempering movement. Must be a multiple of OpenMP threads.
chains=15
walltime=168:00:00

globalFitMode=full
globalFitProfile=nominal

qsubVar=runningMode=mpiGlobalFit,singularityFile="${sifFile}",inputFile=/work/SC/lisa/LDC/LDCdata/Challenge2/LDC2_sangria_training_v2.h5\
,globalFitMode=${globalFitMode},globalFitProfile=${globalFitProfile}\
,vgbFile=$PWD/run/auxiliaryfiles/${globalFitProfile}/ldc_sangria_vgb_list.dat,mbhDirectory=$PWD/run/auxiliaryfiles/${globalFitProfile}/,ucbDirectory=$PWD/run/auxiliaryfiles/${globalFitProfile}/\
,steps="${steps}",OMP_NUM_THREADS="${OMP_NUM_THREADS}",chains="${chains}"
qsub -W block=true -l "${pbsRss}" -l walltime="${walltime}" -v "${qsubVar}" ./run/run_pbs.sh


