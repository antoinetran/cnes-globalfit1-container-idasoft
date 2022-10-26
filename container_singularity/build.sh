#!/bin/sh

scriptDir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

test ! -f "${scriptDir}"/../common.sh && echo "${scriptDir}/../common.sh not found." >&2 && exit 1 
. "${scriptDir}"/common.sh

#export PATH="$PATH":/softs/rh7/singularity/3.10.0/bin
module load singularity/3.10.0

parseArgs() {
  while test 0 != "$#" ; do
    case "$1" in
    -p|--set_proxy)
      proxy_script="$2"
      shift 2
      ;;
    -o|--output-file)
      outputFile="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument $1" >&2
      exit 1 
    esac
  done
}


build() {
  export SINGULARITY_TMPDIR=/singularity #nécessaire depuis un noeud de visu uniquement
  runAndCheck pushd "${scriptDir}" >/dev/null
    runAndCheck singularity build --fakeroot "${outputFile}".tmp ./cnes-lisa-globalfit1-idasoft-hpc.def
    runAndCheck rm "${outputFile}" -f
    runAndCheck mv "${outputFile}".tmp "${outputFile}"
  runAndCheck popd >/dev/null
  runAndCheck chgrp lisa "${outputFile}"
  runAndCheck chmod u=rwX,g=rwX,o=rX "${outputFile}"
}

runAndCheck parseArgs "$@"

if test -z "${outputFile}" ; then
  echo "--output-file is not set" >&2
  exit 1
fi

if test -f "${proxy_script}" ; then
  logInfo "Sourcing ${proxy_script}..."
  runAndCheck . "${proxy_script}"
fi

build "$@"


