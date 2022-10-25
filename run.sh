#!/bin/sh
#PBS -N lisa-trana-globalfit-idasoft
#PBS -l select=1:ncpus=40:mpiprocs=8:mem=100gb:os=rh7:generation=g2019
#PBS -l place=free:group=switch
#PBS -l walltime=00:05:00

# https://gitlab.cnes.fr/hpc/wikiHPC/-/wikis/pbs-exemple-job-mpi says that
# Il est nécessaire d'ajouter le paramètre -l place pour indiquer à PBS que l'on souhaite concaténer les processus sur le même switch infiniband.

#https://gitlab.cnes.fr/hpc/wikiHPC/-/wikis/pbs-ressources

scriptDir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

#test ! -f "${scriptDir}"/common.sh && echo "${scriptDir}/../common.sh not found." >&2 && exit 1
#. "${scriptDir}"/common.sh

logGeneric() {
  logLevel="$1"
  shift
  printf "$(date --iso-8601=s -u) [${logLevel}] %s\n" "$*"
}

logInfo() {
  logGeneric INFO "$@"
}

logError() {
  logGeneric ERROR "$@" >&2
}

_prefixCmdDate() {
  while IFS= read -r line ; do
    printf "%s %s\n" "$(date --iso-8601=s -u)" "${line}"
  done
}

prefixDate() {
  ( "$@" 2>&1 1>&3 3>&- | _prefixCmdDate ) 3>&1 1>&2 | _prefixCmdDate
}

runAndCheck() {
  "$@"
  exitCode="$?"
  test 0 != "${exitCode}" && logError Exit code: "${exitCode}" running: "$@" && exit "${exitCode}"
  return 0
}

# Nombre de threads OpenMP
export OMP_NUM_THREADS=5
# Must be a multiple of OpenMP threads.
globalfit_chains=15
# Defaults steps is 100000. Value of less than 10000 might be too low and causes segmentation fault..
steps=8000
# --no-burnin
globalfitExtraArgs="--debug"
# Verification mode: use ucb vgb mbh files
# Blind mode: put the value below to false.
verificationMode=false

fmin=0.0003
samples=128

#### Full year
#Tobs=31457280
#padding=128
####
#### 3 months
Tobs=7864320
padding=32
####
Tstart=0
sources=40


loadModules() {
  module load singularity/3.10.0
  module load openmpi/3.1.4 #(version doit être la même que celle utilisée dans le conteneur pour compiler)
  module load monitoring/2.0
}

showHelp() {
  echo "-h|--help: show help"
  echo "-g|--globalFitMode: mode. Accept: verification or blind"
  echo "-r|--runningMode: running mode. Accept: mpiGlobalFit, mpiHelloRingC, mpiHelloMpiTest"
  echo "-s|--singularityFile: singularity SIF file."
  echo "-i|--inputFile: for singularityMode=mpiGlobalFit only. Path of the input file. It must be in Sangria V2 format."
  echo "--vgbFile: for runningMode=mpiGlobalFit,globalFitMode=verification only. path of the auxiliary file VGB."
  echo "--mbhDirectory: for singularityMode=mpiGlobalFit only. Path of the directory containing the auxiliary file MBH: search_sources.dat"
  echo "--ucbFile: for singularityMode=mpiGlobalFit only. WARNING: this parameter is not used. However the current directory must contain ucb_frequency_spacing.dat."
}

parseArgs() {
  while test 0 != "$#" ; do
    case "$1" in
    -h|--help)
      showHelp
      shift
      ;;
    -g|--globalFitMode)
      globalFitMode="$2"
      shift 2
      ;;
    -r|--runningMode)
      runningMode="$2"
      shift 2
      ;;
    -s|--singularityFile)
      singularityFile="$2"
      shift 2
      ;;
    -i|--inputFile)
      inputFile="$2"
      shift 2
      ;;
    --vgbFile)
      vgbFile="$2"
      shift 2
      ;;
    --mbhDirectory)
      mbhDirectory="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument $1" >&2
      exit 1
    esac
  done

  if test -z "${runningMode}" ; then
     logError "Missing runningMode"
     exit 11
  fi
}

pbsArgs() {
      globalFitMode="${globalFitMode}"
      runningMode="${runningMode}"
      singularityFile="${singularityFile}"
      inputFile="${inputFile}"
      vgbFile="${vgbFile}"
      mbhDirectory="${mbhDirectory}"
}

mpiRun() {
  if test -z "${PBS_NODEFILE}" ; then
    echo "[ERROR] missing variable PBS_NODEFILE. Did you launched with qsub?" >&2
    exit 11
  fi

  # nombre de processus MPI
  nb_procs=$(wc -l $PBS_NODEFILE | cut -d" " -f 1)
  echo "nb_procs = $nb_procs"
  mpirun -x OMP_NUM_THREADS -n "${nb_procs}" --hostfile "${PBS_NODEFILE}" --mca orte_base_help_aggregate 0 "$@"
}

helloworldMpiTest() {
  printAndRun mpiRun singularity exec "${singularityFile}" /container/mpitest
}
helloworldRingC() {
  printAndRun mpiRun singularity exec "${singularityFile}" /container/ring_c
}

printAndRun() {
  echo Running "$@"
  "$@"
}

globalfit() {
  outputDir="${PBS_O_WORKDIR}"
  workDir="${PBS_O_WORKDIR}"
  if test "verification" == "${globalFitMode}" ; then
    # In verification mode, the ucb ucb_frequency_spacing.dat must be on working directory. Thus we set pwd.
    verificationModeSingularityArg="--pwd ${workDir} --bind "${vgbFile}":/data/vgb --bind "${mbhDirectory}":/data/mbh"
    verificationModeCmdArg="--known-sources /data/vgb --mbh-search-path /data/mbh"
  else
    verificationModeSingularityArg=""
    verificationModeCmdArg=""
  fi
  logInfo "Verification mode? ${verificationMode}"
  printAndRun mpiRun \
    singularity exec \
    --workdir "${workDir}" --bind "${inputFile}":/data/input ${verificationModeSingularityArg} \
    "${singularityFile}" /usr/local/lib/ldasoft/bin/global_fit \
      --rundir "${outputDir}" \
      --h5-data "/data/input" --sangria \
      --fmin "${fmin}" \
      --chains "${globalfit_chains}" \
      --start-time ${Tstart} \
      --duration ${Tobs} \
      --samples ${samples} \
      --padding ${padding} \
      --sources ${sources} \
      ${verificationModeCmdArg} \
      "$@"
}

# Goal: start and stop monitoring, and return the exit code only after stopping the monitoring.
# Takes the monitoring name as first argument, then the commands arguments.
monitoring() {
  monitoringName="$1"
  shift
  logInfo "Starting monitoring..."
  start_monitoring.sh --name "${monitoringName}"
  "$@"
  exitCode="$?"
  logInfo "Execution ended with exit code ${exitCode}. Stopping monitoring..."
  stop_monitoring.sh --name "${monitoringName}"
  return "${exitCode}"
}

main() {
  set -x
  # If launched with qsub, this gets the variable with -v.
  pbsArgs
  if test -z "${runningMode}" ; then
    # Case without qsub.
    parseArgs "$@"
  fi
  loadModules
  if test mpiGlobalFit == "${runningMode}" ; then
    prefixDate runAndCheck monitoring job_"${PBS_JOBNAME}_${PBS_JOBID}" globalfit ${globalfitExtraArgs}  --steps "${steps}"
  elif test mpiHelloRingC == "${runningMode}" ; then
    prefixDate runAndCheck helloworldRingC
  elif test mpiHelloMpiTest == "${runningMode}" ; then
    prefixDate runAndCheck helloworldMpiTest
  fi
}




logInfo "Beginning computation $0 with steps ${steps}" "$@"

main "$@"

logInfo "End computation $0" "$@"


