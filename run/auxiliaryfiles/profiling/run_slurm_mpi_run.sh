#!/bin/bash
#SBATCH --job-name=LDC2a_Prod
#SBATCH --output=slurm_profile_run.out
#SBATCH --error=slurm_profile_run.err
#SBATCH --partition=hpc-demand-36
#SBATCH --ntasks=25
#SBATCH --tasks-per-node=5
#SBATCH --cpus-per-task=8

globalfit=~/opt/bin/global_fit
data=/Users/tyson/ldc/sangria/data/LDC2_sangria_training_v2.h5
vgb=./ldc_sangria_vgb_list.dat
mbh=./

Tobs=7864320
padding=32
outdir=./global_fit_profiling_run
sources=40

#Set up whatever package we need to run with
module load gsl-2.7-gcc-9.3.0-kk67rc7
module load hdf5-1.13.0-gcc-9.3.0-7kjrzwi

cmd="${globalfit} \
--h5-data ${data} \
--sangria \
--chains 16 \
--duration ${Tobs} \
--padding ${padding} \
--sources ${sources} \
--rundir ${outdir} \
--mbh-search-path ${mbh} \
--known-sources ${vgb} \
"

echo $cmd
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

mpirun -np $SLURM_NTASKS $cmd
