#!/bin/sh

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


