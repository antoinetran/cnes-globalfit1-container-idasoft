#!/bin/bash
#SBATCH --job-name=LDC2a_Prod
#SBATCH --output=slurm_12.out
#SBATCH --error=slurm_12.err
#SBATCH --partition=hpc-demand-36
#SBATCH --ntasks=214
#SBATCH --ntasks-per-node=12
#SBATCH --cpus-per-task=3
#SBATCH --hint multithread

globalfit=/shared/opt/bin/global_fit
data=/data/ldc/sangria/LDC2_sangria_training_v2.h5
vgb=/data/ldc/sangria/ldc_sangria_vgb_list.dat
mbh=/data/ldc/sangria/

fmin=0.0003
samples=128
samples_max=128

#Tobs=3932160
#padding=16
#outdir=/shared/ldc/sangria/prod/sangria_training_01mo

#Tobs=7864320
#padding=32
#ucb=/data/ldc/sangria/sangria_training_01mo/gb_catalog.cache
#outdir=/shared/ldc/sangria/prod/sangria_training_03mo

#Tobs=15728640
#padding=64
#ucb=/data/ldc/sangria/sangria_training_03mo/gb_catalog.cache
#outdir=/shared/ldc/sangria/prod/sangria_training_06mo

#Tobs=23592960
#padding=128
#ucb=/data/ldc/sangria/sangria_training_06mo/gb_catalog.cache
#outdir=/shared/ldc/sangria/prod/sangria_training_09mo

Tobs=31457280
padding=128
ucb=/data/ldc/sangria/sangria_training_06mo/gb_catalog.cache
outdir=/shared/ldc/sangria/prod/sangria_training_12mo

Tstart=0
sources=40

#Set up whatever package we need to run with
module load gsl-2.7-gcc-9.3.0-kk67rc7
module load hdf5-1.13.0-gcc-9.3.0-7kjrzwi

cmd="${globalfit} \
--h5-data ${data} \
--sangria \
--fmin ${fmin} \
--chains 18 \
--start-time ${Tstart} \
--duration ${Tobs} \
--samples ${samples} \
--padding ${padding} \
--sources ${sources} \
--rundir ${outdir} \
--known-sources ${vgb} \
--catalog ${ucb} \
"
#--mbh-search-path ${mbh} \


echo $cmd
export OMP_NUM_THREADS=6

mpirun -np $SLURM_NTASKS $cmd
#(time mpirun -np $SLURM_NTASKS $cmd) 1> run.out 2>&1
