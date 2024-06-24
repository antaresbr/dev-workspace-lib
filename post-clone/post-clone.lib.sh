#!/bin/bash

[ "${BASH_SOURCE[0]}" -ef "$0" ] && echo "$(basename "$0") | ERROR: This file must be sourced" && exit 1

if [ -z "${POST_CLONE_LIB_SH}" ]
then

POST_CLONE_LIB_SH="loaded"

function pclError() {
  local msgPrefix="post-clone-lib"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  pcsError "${msgPrefix}" "$@"
  exit 1
}


[ -z "${WORKSPACE_BASE_LIB_SH}" ] && pclError "WORKSPACE_BASE_LIB_SH not defined"

[ -z "${SCRIPT_DIR}" ] && SCRIPT_DIR="$(dirname "$0")"
[ -z "${BASE_DIR}" ] && BASE_DIR="$(dirname "${SCRIPT_DIR}")"


function pclLoadSavedParams() {
  if [ -f "${SCRIPT_DIR}/setup.local.env" ]
  then
    echo ""
    envVarRead "Load saved post-clone parameters?" "pLoadParams" "default:yes|lower-case|hide-values" "y|yes|n|no"
    [ "${pLoadParams:0:1}" == "n" ] || wsSourceFile "${SCRIPT_DIR}/setup.local.env"
  fi
}


function setMode() {
  local zTarget="$1"
  local zMode="$2"

  [ -z "${zTarget}" ] && pclError "setMode" "Parameter not supplied, zTarget"

  if [ "${SETMODE_SHOW_TARGET,,}" == "true" ]
  then
    local prefix="${zTarget} : mode ${zMode}"
  else
    local prefix="  + mode ${zMode}"
  fi
  local suffix=""

  if [ -n "${zMode}" ]
  then
    sudo chmod ${zMode} ${zTarget}
    [ $? -ne 0 ] && local suffix=" ! falha na ação"
    echo "${prefix}${suffix}"
  fi
}


function setOwner() {
  local zTarget="$1"
  local zOwner="$2"

  [ -z "${zTarget}" ] && pclError "setOwner" "Parameter not supplied, zTarget"

  [ -z "${zOwner}" ] && local zOwner="${DEFAULT_USER}:${DEFAULT_GROUP}"

  if [ "${SETOWNER_SHOW_TARGET,,}" == "true" ]
  then
    echo ""
    echo "Alvo: ${zTarget} "
  fi

  sudo chown ${zOwner} ${zTarget}
  if [ $? -eq 0 ]
  then
    echo "  + owner ${zOwner}"
  else
    echo "  ! owner: falha na ação"
  fi
}


function templateFile() {
  local zTarget="$1"
  local zSource="$2"
  local zMode="$3"
  local zOwner="$4"

  [ -z "${zTarget}" ] && pclError "templateFile" "Parameter not supplied, zTarget"

  echo ""
  echo "File ${zTarget}"

  [ -f "${zTarget}" ] && echo "  + already exists" && return

  [ -z "${zSource}" ] && [ -f "${zTarget}.template" ] && zSource="${zTarget}.template"
  [ -z "${zSource}" ] && [ -f "${zTarget}.example" ] && zSource="${zTarget}.example"
  [ -z "${zSource}" ] && pclError "templateFile" "Parameter not supplied, zSource"
  [ ! -f "${zSource}" ] && pclError "templateFile" "File not found, ${zSource}"

  local suffix=""
  if [ "${zSource:(-8)}" == ".example" ]
  then
    cat "${zSource}" \
      | sed "s/{{ENVIRONMENT}}/${pEnvironment}/g" \
      | sed "s/{{SAIL_USERNAME}}/${SAIL_USERNAME}/g" \
      | sed "s/{{SAIL_USERID}}/${SAIL_USERID}/g" \
      | sudo tee "${zTarget}" > /dev/null
    [ $? -eq 0 ] && local suffix="  + created"
  else
    eval "cat << EOF
$(<${zSource})
EOF
"     | sudo tee "${zTarget}" > /dev/null
    [ $? -eq 0 ] && local suffix="  + created"
  fi
  [ -z "${suffix}" ] && local suffix="  ! failed to create"
  echo "${suffix}"

  [ "$(type -t localTemplateFile)" == "function" ] && localTemplateFile "${zTarget}"

  setMode "${zTarget}" "${zMode}"
  setOwner "${zTarget}" "${zOwner}"
}


function certifyPath() {
  local zTarget="$1"
  local zMode="$2"
  local zOwner="$3"

  [ -z "${zTarget}" ] && pclError "certifyPath" "Parameter not supplied, zTarget"

  echo ""
  echo "Pasta ${zTarget}"

  if [ -d "${zTarget}" ]
  then
    echo "  + já existe"
  else
    sudo mkdir "${zTarget}"
    if [ $? -eq 0 ]
    then
      echo "  + criado"
    else
      echo "  ! falha ao criar"
    fi
  fi

  setMode "${zTarget}" "${zMode}"
  setOwner "${zTarget}" "${zOwner}"
}


function sailSetup() {
  wsCreateLink "../.workspace-lib/sail" "sail/lib"
  
  ENV_SAIL_FILE="sail/.env.sail"
  templateFile "${ENV_SAIL_FILE}"

  echo ""
  echo "sail/sail shortcut"
  if [ -f "sail/sail" ]
  then
    echo "  + already exists"
  else
    ln -v -s lib/sail.sh sail/sail
  fi

  [ "$(type -t localSailSetup)" == "function" ] && localSailSetup
}


function sailBuild() {
  if [ "${SAIL_BUILD,,}" != "true" ]
  then
    echo ""
    echo "sailBuild | Ignored due to SAIL_BUILD=${SAIL_BUILD}"
    return
  fi
  echo ""
  echo "sailBuild | Building images"
  ${BASE_DIR}/sail/sail build
  if [ $? -ne 0 ]
  then
    pclError "sailBuild | failed to create images"
  fi
}


function sailAppExec() {
  if [ -n "${SAIL_EXEC_APP_USER}" ]
  then
    sail/sail exec --user ${SAIL_EXEC_APP_USER} app $@
    local exitCode=$?
  else
    sail/sail exec app $@
    local exitCode=$?
  fi
  if [ $exitCode -ne 0 ] && [ -z "${SAIL_EXEC_NO_CHECK_SUCCESS}" ]
  then
    pclError "sailAppExec" "Failed to run command, sail/sail exec ${sailUser} app $@"
  fi
}


function sailAppExecAsRoot() {
  SAIL_EXEC_APP_USER="root"
  sailAppExec $@
  unset SAIL_EXEC_APP_USER
}


DEFAULT_USER="$(getent passwd $(id -u) | cut -d: -f1)"
[ -n "${DEFAULT_USER}" ] || pclError "Fail to get DEFAULT_USER"

DEFAULT_GROUP="$(getent group $(id -g) | cut -d: -f1)"
[ -n "${DEFAULT_GROUP}" ] || pclError "Fail to get DEFAULT_GROUP"

[ -n "${SAIL_BUILD}" ] || SAIL_BUILD="true"

fi