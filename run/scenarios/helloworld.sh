#!/bin/sh

. ~/set_proxy.sh
sifFile=/work/SC/lisa/${USER}/cnes-lisa-globalfit1-idasoft-hpc.sif

# select=Number of node
# ncpus=Number of Cpus per node for all processes
# mpiprocs=Number of Cpus per node allocated for MPI.
pbsRss="select=1:ncpus=4:mpiprocs=4:mem=1gb:os=rh7:generation=g2019"
walltime=00:05:00

qsubVar=runningMode=mpiHelloRingC,singularityFile="${sifFile}"
qsub -W block=true -l "${pbsRss}" -l walltime="${walltime}" -v "${qsubVar}" ./run/run_pbs.sh


