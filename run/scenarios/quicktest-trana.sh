#!/bin/sh

sifFile=/work/SC/lisa/${USER}/cnes-lisa-globalfit1-idasoft-hpc.sif

# Default is 100000. Estimation time (depends on the ressources): default steps takes around a week. 10000 steps takes around 30min.
steps=10000
# select=Number of node
# ncpus=Number of Cpus per node for all processes
# mpiprocs=Number of Cpus per node allocated for MPI.
pbsRss="select=1:ncpus=40:mpiprocs=8:mem=50gb:os=rh7:generation=g2019"
# Number of OpenMP threads. The higher the lesser for walltime (better).
ompNumThreads=5
# Number of chains for tempering movement. Must be a multiple of OpenMP threads.
chains=15
walltime=00:30:00

globalFitMode=full
globalFitProfile=nominal

qsubVar=pbsRss="${pbsRss}",runningMode=mpiGlobalFit,singularityFile="${sifFile}",inputFile=/work/SC/lisa/LDC/LDCdata/Challenge2/LDC2_sangria_training_v2.h5\
,globalFitMode=${globalFitMode},globalFitProfile=${globalFitProfile}\
,vgbFile=$PWD/run/auxiliaryfiles/${globalFitProfile}/ldc_sangria_vgb_list.dat,mbhDirectory=$PWD/run/auxiliaryfiles/${globalFitProfile}/,ucbDirectory=$PWD/run/auxiliaryfiles/${globalFitProfile}/\
,steps="${steps}",ompNumThreads="${ompNumThreads}",chains="${chains}"
sudo qsub -u trana -W block=false -l "${pbsRss}" -l walltime="${walltime}" -v "${qsubVar}" ./run/run_pbs.sh


