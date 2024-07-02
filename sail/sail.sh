#!/bin/bash

SAIL_DIR="$(dirname "$0")"
SAIL_DIR="$(cd "${SAIL_DIR}" && pwd)"
SAIL_DOCKER_DIR="${SAIL_DIR}/docker"
APP_DIR=$(dirname "${SAIL_DIR}")
START_DIR=$(pwd)

export SAIL_DIR
export SAIL_DOCKER_DIR
export APP_DIR

sailSourceFile="${SAIL_DIR}/lib/sail.lib.sh"
[ ! -f "${sailSourceFile}" ] && echo "ERROR: File not found: ${sailSourceFile}" && exit 1
source "${sailSourceFile}"
[ $? -ne 0 ] && echo "ERROR: Fail to source: ${sailSourceFile}" && exit 1

pAction="$1"
shift

cd "${SAIL_DOCKER_DIR}"

COMPOSE_CMD="${COMPOSE_BIN} ${COMPOSE_CONFIGS}"

case "${pAction}" in
  'build')
      sailTriggerAction "pre"
      ${COMPOSE_CMD} build $@
      sailTriggerAction "pos"
  ;;
  'config')
      sailTriggerAction "pre"
      ${COMPOSE_CMD} config $@
      sailTriggerAction "pos"
  ;;
  'down')
      sailTriggerAction "pre"
      ${COMPOSE_CMD} down $@
      sailExternalNetworks_down
      sailTriggerAction "pos"
  ;;
  'exec' | 'shell')
      if [ "$1" == '--user' ]
      then
          shift
          pUser="$1"
          shift
      fi

      pService="$1"
      shift
      [ -z "$pService" ] && sailError "${pAction}: Service no supplied"

      sailServiceRunning "${pService}"

      if [ -z "${pUser}" ]
      then
          serviceUser="SAIL_SERVICE_${pService^^}_USER"
          pUser="${!serviceUser}"
      fi
      [ -n "${pUser}" ] && pUser="--user ${pUser}"

      zShell=""
      if [ "${pAction}" == "shell" ]
      then
          serviceShell="SAIL_SERVICE_${pService^^}_SHELL"
          zShell="${!serviceShell}"
          [ -z "${zShell}" ] && zShell="/bin/bash"
      fi

      sailTriggerAction "pre"
      ${COMPOSE_CMD} exec $pUser ${pService} ${zShell} "$@"
      _ec=$?
      [ "$_ec" -ne 0 ] || sailTriggerAction "pos"
      [ "$_ec" -eq 0 ] || exit $_ec
  ;;
  'logs')
      sailTriggerAction "pre"
      ${COMPOSE_CMD} logs $@
      sailTriggerAction "pos"
  ;;
  'ps')
      sailTriggerAction "pre"
      ${COMPOSE_CMD} ps $@
      sailTriggerAction "pos"
  ;;
  'restart' | 'rm' | 'start' | 'stop')
      pService="$1"
      [ -z "$pService" ] && sailError "${pAction}: Service not supplied"

      sailTriggerAction "pre"
      ${COMPOSE_CMD} ${pAction} ${pService} $@
      sailTriggerAction "pos"
  ;;
  'up')
      sailTriggerAction "pre"
      sailExternalNetworks_up
      ${COMPOSE_CMD} up $@
      sailTriggerAction "pos"
  ;;
  'help' | '--help')
    script=$(basename "$0")
    sailHelp "
Use: ${script} <action> ...

Ações:

  build         Re/Build service images
  config        Show resulting compose config file
  down          Stop and remove a service
  exec          Run a command in a service
  logs          Show service logs
  ps            Show service list
  restart       Restart service containers
  rm            Remove stopped service containers
  shell         Open a shell in a service container
  start         Start service containers
  stop          Stop service containers
  help          Show this help

To get action help: ${script} <action> help
"
  ;;
  *)
      echo "ERROR: Invalid or not supplied action: '${pAction}'"
      exit 1
  ;;
esac

cd "${START_DIR}"
