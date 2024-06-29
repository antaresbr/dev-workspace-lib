#!/bin/bash

if [ -z "${SAIL_LIB_SH}" ]
then

SAIL_LIB_SH="loaded"

function sailError() {
    echo ""
    echo "ERROR: $1"
    echo ""
    exit 1
}

function sailHelp() {
  local script=$(basename "$0")
  echo -e "
${script}: Stack command tool
$@"
  exit 0
}

function sailSourceFile() {
    local zFile="$1"

    [ ! -f "${zFile}" ] && sailError "File not found: ${zFile}"
    source "${zFile}"
    [ $? -ne 0 ] && sailError "Fail to source file: ${zFile}"
}

function sailRunIfExists() {
    local zFile="$1" && shift
    if [ -f "${zFile}" ]
    then
      "${zFile}" $@
    fi
}

function sailAddComposeConfig() {
  [ $# -lt 1 ] && sailError "sailAddComposeConfig | Parâmetro não informado, zFile"
  while [ $? -gt 0 ]
  do
    local zFile="$1"
    shift

    [ -f "${SAIL_DOCKER_DIR}/${zFile}.yaml" ] && local zFile="${zFile}.yaml"
    [ -f "${SAIL_DOCKER_DIR}/${zFile}.yml" ] && local zFile="${zFile}.yml"

    [ ! -f "${SAIL_DOCKER_DIR}/${zFile}" ] && sailError "sailAddComposeConfig | File not found, ${zFile}"

    [ -n "${COMPOSE_CONFIGS}" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} "
    export COMPOSE_CONFIGS="${COMPOSE_CONFIGS}--file ${zFile}"
  done
}

function sailExternalNetworks_up() {
  local networks="${SAIL_EXTERNAL_NETWORKS}"
  [ -n "${networks}" ] || networks="sail-net"
  local network=""
  for network in ${networks}
  do
    ${DOCKER_BIN} network inspect ${network} &> /dev/null
    [ $? -eq 0 ] || ${DOCKER_BIN} network create ${network}
    [ $? -eq 0 ] || sailError "Fail to create network '${network}'"
  done
}

function sailExternalNetworks_down() {
  local networks="${SAIL_EXTERNAL_NETWORKS}"
  [ -n "${networks}" ] || networks="sail-net"
  local network=""
  for network in ${networks}
  do
    local netCount="$(${DOCKER_BIN} network inspect ${network} | jq -r '.[0].Containers | length')"
    if [ $? -eq 0 ] && [ "${netCount}" == "0" ]
    then
      ${DOCKER_BIN} network rm ${network}
    fi
  done
}

function sailTriggerAction() {
    local zPhase="$1" && shift
    sailRunIfExists "${SAIL_DIR}/triggers/${zPhase}-${pAction}.sh"
}

function sailServiceRunning() {
    local zService="$1"
    ${COMPOSE_CMD} ps "${pService}" &> /dev/null
    [ $? -ne 0 ] && sailError "Service is not running: ${pService}"
}

sailSourceFile "${SAIL_DIR}/lib/sail.env.sh"
sailSourceFile "${SAIL_DIR}/project.env.sh"

COMPOSE_BIN=$(which docker-compose)
if [ -n "${COMPOSE_BIN}" ]
then
  COMPOSE_BIN="docker-compose"
else
  COMPOSE_BIN=$(which docker)
  if [ -n "${COMPOSE_BIN}" ]
  then
    COMPOSE_BIN="docker compose"
    ${COMPOSE_BIN} version &> /dev/null
    [ $? -ne 0 ] && COMPOSE_BIN=""
  fi
fi
if [ -z "${COMPOSE_BIN}" ]
then
  sailError "Impossible to get COPOSE_BIN"
fi

fi
