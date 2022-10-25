# Project LISA for CNES.

This repository build the globalfit1 Idasoft and deploy it in a docker container to https://hub.docker.com/r/antoinetran/cnes-lisa-globalfit1-idasoft.

## How to build


### With Jenkins

#### Prerequisites:

- variable registryPrefix = antoinetran/
- in Jenkins credential store: credentialsId of Registry id: lisa_dockerhub

Creates in Jenkins a pipeline job with SCM attached to this git repository. Add the variable in the job. Then build it.

### In command-line

Just launch:

```
docker build .
```


## How to run


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

```
qsub -W block=true -v runningMode=mpiHelloRingC,singularityFile=/work/scratch/trana/cnes-lisa-globalfit1-idasoft.sif ./run.sh
qsub -W block=true -v runningMode=mpiHelloMpiTest,singularityFile=/work/scratch/trana/cnes-lisa-globalfit1-idasoft.sif ./run.sh
qsub -W block=true -v runningMode=mpiGlobalFit,singularityFile=/work/scratch/trana/cnes-lisa-globalfit1-idasoft.sif,inputFile=/work/SC/lisa/LDC/LDCdata/Challenge2/LDC2_sangria_training_v2.h5,globalFitMode=blind ./run.sh
qsub -W block=true -v runningMode=mpiGlobalFit,singularityFile=/work/scratch/trana/cnes-lisa-globalfit1-idasoft.sif,inputFile=/work/SC/lisa/LDC/LDCdata/Challenge2/LDC2_sangria_training_v2.h5,globalFitMode=verification,vgbFile=$PWD/ldc_sangria_vgb_list.dat,mbhDirectory=$PWD/ ./run.sh
```


