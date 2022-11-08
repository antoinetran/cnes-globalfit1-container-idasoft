# Project LISA for CNES.

This repository builds the globalfit1 Idasoft (https://github.com/tlittenberg/ldasoft) and deploys it as a docker container to https://hub.docker.com/r/antoinetran/cnes-lisa-globalfit1-idasoft.

## How to build docker container

### With Jenkins

#### Prerequisites:

- variable registryPrefix = antoinetran/
- in Jenkins credential store: credentialsId of Registry id: lisa_dockerhub

Creates in Jenkins a pipeline job with SCM attached to this git repository. Add the variable in the job. Then build it. This will push the docker container to the registry described beyond.

### In command-line

Just launch:

```
cd ./container_docker
docker build .
```

This will NOT push the docker container to the registry described beyond.

## How to build singularity container

Prerequisites:
* docker container built and deployed to the registry defined beyond
* singularity executable in PATH

### General case

```
outputFile=...
singularity build --fakeroot "${outputFile}" docker://antoinetran/cnes-lisa-globalfit1-idasoft:dev
```

### CNES HPC case

The CNES HPC only works with singularity container and needs infiniband network driver to get the maximum performance. The driver is present in the cluster so the singularity build must be done on CNES HPC. 

Prerequisite in CNES HPC:
* have ~/set_proxy.sh that set proxy

To build:

```
. ~/set_proxy.sh
outputFile=$HOME/cnes-lisa-globalfit1-idasoft-hpc.sif
./container_singularity/build.sh -o "${outputFile}"
mkdir /work/SC/lisa/${USER} -p
mv "${outputFile}" /work/SC/lisa/${USER}/cnes-lisa-globalfit1-idasoft-hpc.sif
```

Warning: do not put output directory to the shared file-system /work. Eg: this command will not work.

```
./build.sh -o /work/SC/lisa/cnes-lisa-globalfit1-idasoft-hpc.sif
```


## How to run

#### Inspect docker image

```
docker run --rm -ti antoinetran/cnes-lisa-globalfit1-idasoft:dev tree /usr/local/lib/ldasoft
/usr/local/lib/ldasoft
|-- bin
|   |-- gaussian_mixture_model
|   |-- gb_catalog
|   |-- gb_mcmc
|   |-- noise_mcmc
|   `-- vb_mcmc
|-- include
|   |-- Constants.h
|   |-- GalacticBinary.h
|   |-- GalacticBinaryCatalog.h
|   |-- GalacticBinaryData.h
|   |-- GalacticBinaryFStatistic.h
|   |-- GalacticBinaryIO.h
|   |-- GalacticBinaryMCMC.h
|   |-- GalacticBinaryMath.h
|   |-- GalacticBinaryModel.h
|   |-- GalacticBinaryPrior.h
|   |-- GalacticBinaryProposal.h
|   |-- GalacticBinaryWaveform.h
|   |-- LISA.h
|   |-- Noise.h
|   |-- gbmcmc.h
|   `-- gitversion.h
`-- lib
    |-- libgbmcmc.a
    |-- liblisa.a
    |-- libnoise.a
    `-- libtools.a

3 directories, 25 files
docker run --rm -ti antoinetran/cnes-lisa-globalfit1-idasoft:dev tree /usr/local/lib/mbh
/usr/local/lib/mbh
|-- bin
|   |-- mbh_mcmc
|   `-- mbh_post
|-- include
|   |-- Constants.h
|   |-- Declarations.h
|   |-- IMRPhenomD.h
|   |-- IMRPhenomD_internals.h
|   `-- mbh.h
`-- lib
    |-- cmake
    |   `-- mbh
    |       |-- MBHConfig-release.cmake
    |       `-- MBHConfig.cmake
    `-- libmbh.a

5 directories, 10 files

```


#### With PBS

Prerequisites:
* to have Sangria V2 dataset (https://lisa-ldc.lal.in2p3.fr/media/uploads/LDC2_sangria_training_v2.h5) in /work/SC/lisa/LDC/LDCdata/Challenge2/LDC2_sangria_training_v2.h5
* to have qsub in PATH
* to have singularity container as SIF file in

```
sifFile=/work/SC/lisa/${USER}/cnes-lisa-globalfit1-idasoft-hpc.sif
```

These commands will run 2 differents HelloWorld program.
```
qsub -W block=true -v runningMode=mpiHelloRingC,singularityFile="${sifFile}" ./run/run_pbs.sh
qsub -W block=true -v runningMode=mpiHelloMpiTest,singularityFile="${sifFile}" ./run/run_pbs.sh
```

For Globalfit, the performance tuning are set like this (this will override variables set in script):
```
# Default is 100000. Estimation time (depends on the ressources): default steps takes around a week. 10000 steps takes around 30min.
steps=10000
# select=Number of node
# ncpus=Number of Cpus per node for all processes
# mpiprocs=Number of Cpus per node allocated for MPI.
pbsRss="select=1:ncpus=40:mpiprocs=8:mem=100gb:os=rh7:generation=g2019"
# Number of OpenMP threads. The higher the lesser for walltime (better).
OMP_NUM_THREADS=5
# Number of chains for tempering movement. Must be a multiple of OpenMP threads.
chains=15
walltime=01:00:00
```

This will set Globalfit to blind mode.

```
globalFitMode=blind
```

This will set Globalfit to verification mode, using auxiliary files in ./run directory.

```
globalFitMode=verification
```

This will use auxiliary files for nominal profile.

```
globalFitProfile=nominal
```

This will use auxiliary files for profiling profile.

```
globalFitProfile=profiling
```


This will run Globalfit with OpenMPI and OpenMP using PBS.

```
qsubVar=runningMode=mpiGlobalFit,singularityFile="${sifFile}",inputFile=/work/SC/lisa/LDC/LDCdata/Challenge2/LDC2_sangria_training_v2.h5\
,globalFitMode=${globalFitMode},globalFitProfile=${globalFitProfile}\
,vgbFile=$PWD/run/auxiliaryfiles/${globalFitProfile}/ldc_sangria_vgb_list.dat,mbhDirectory=$PWD/run/auxiliaryfiles/${globalFitProfile}/,ucbDirectory=$PWD/run/auxiliaryfiles/${globalFitProfile}/\
,steps="${steps}",OMP_NUM_THREADS="${OMP_NUM_THREADS}",chains="${chains}"
qsub -W block=true -l "${pbsRss}" -l walltime="${walltime}" -v "${qsubVar}" ./run/run_pbs.sh
```

#### With SLURM

TODO.
See Tyson's original files ./run/run_slurm_mpi_run.sh in auxiliaryfiles directory.

