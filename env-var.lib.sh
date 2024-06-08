#!/bin/bash

if [ -z "${ENV_VAR_LIB_SH}" ]
then

ENV_VAR_LIB_SH="loaded"

function evError() {
  local msgPrefix="env-var-lib"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  if [[ $(type -t wsError) == function ]]
  then
    wsError "${msgPrefix}" "$@"
  else
    echo ""
    echo "${msgPrefix} | ERROR: $@"
    echo ""
  fi
  exit 1
}


#-- envVarSet : Sets a environment variable
#   parameters
#     zVar   : Variable name
#     zValue : Variable value
function envVarSet () {
  local zVar="$1"
  local zValue="$2"
  declare -g "${zVar}=${zValue}"
}


#-- envVarGet : Gets the environment variable value
#   parameters
#     zVar   : Variable name
function envVarGet () {
  local zVar="$1"
  echo -n "${!zVar}"
}


#-- envVarValidate : Validates environment variable value in a possible value list
#   parameters
#     zVar     : Variable name
#     zValues  : Possible values
#     zOptions : Validate options
function envVarValidate() {
  local zVar="$1" && shift
  local zValues="$1" && shift
  local zOptions="$1" && shift

  [ -z "${zVar}" ] && evError "envVarValidate" "Parameter not supplied, zVar"

  unset envVarValidate_result

  IFS=$'|'
  local option
  for option in ${zOptions}
  do
    [ "${option}" == "debug" ] && local oDebug="${option}" && option=""
    [ "${option}" == "ignore-case" ] && local oIgnoreCase="${option}" && option=""
    [ "${option}" == "required" ] && local oRequired="${option}" && option=""
    [ -z "${option}" ] && continue
    evError "envVarValidate" "Opção inválida: ${option}"
  done
  unset IFS

  if [ -n "${oDebug}" ]
  then
    echo ""
    echo "---[ envVarValidate : debug ]---"
    echo ":: zVar         : ${zVar}"
    echo ":: zValues      : ${zValues}"
    echo ":: zOptions     : ${zOptions}"
    echo "   oDebug       : ${oDebug}"
    echo "   oIgnoreCase  : ${oIgnoreCase}"
    echo "   oRequired    : ${oRequired}"
    echo ""
  fi

  local varValue="${!zVar}"

  [ -z "${varValue}" ] && [ -n "${oRequired}" ] && envVarValidate_result="envVarValidate | Valor requerido" && return

  [ -z "${zValues}" ] && return

  IFS=$'|'
  local value
  for value in ${zValues}
  do
    [ "${varValue}" == "${value}" ] && return
    [ "${varValue,,}" == "${value,,}" ] && [ -n "${oIgnoreCase}" ] && return
  done
  unset IFS
  envVarValidate_result="
envVarValidate | Valor inválido: ${varValue}
  + Variável  : ${zVar}
  + Permitido : ${zValues}
"
}


#-- envVarRead : Read environment variable value
#   parameters
#     zMsg     : Prompt message
#     zVar     : Variable name
#     zOptions : Read options
#     zValues  : Possible values
function envVarRead() {
  local zMsg="$1" && shift
  local zVar="$1" && shift
  local zOptions="$1" && shift
  local zValues="$1" && shift

  [ -z "${zVar}" ] && evError "envVarRead" "Parâmetro não informado, zVar"
  
  IFS=$'|'
  local option
  for option in ${zOptions}
  do
    [ "${option}" == "auto-default" ] && local oAutoDefault="${option}" && option=""
    [ "${option}" == "debug" ] && local oDebug="${option}" && option=""
    [ "${option:0:8}" == "default:" ] && local oDefault="${option}" && option=""
    [ "${option}" == "hide-default" ] && local oHideDefault="${option}" && option=""
    [ "${option}" == "hide-values" ] && local oHideValues="${option}" && option=""
    [ "${option}" == "ignore-case" ] && local oIgnoreCase="${option}" && option=""
    [ "${option}" == "lower-case" ] && local oLowerCase="${option}" && option=""
    [ "${option}" == "no-trim" ] && local oNoTrim="${option}" && option=""
    [ "${option}" == "upper-case" ] && local oUpperCase="${option}" && option=""
    [ "${option}" == "required" ] && local oRequired="${option}" && option=""
    [ -z "${option}" ] && continue
    evError "envVarRead" "Opção inválida: ${option}"
  done
  unset IFS

  [ -n "${oAutoDefault}" ] && [ -n "${!zVar}" ] && local oDefault="default:${!zVar}"

  unset ${zVar}

  if [ -n "${oDebug}" ]
  then
    echo ""
    echo "---[ envVarRead : debug ]---"
    echo ":: zOptions     : ${zOptions}"
    echo "   oAutoDefault : ${oAutoDefault}"
    echo "   oDebug       : ${oDebug}"
    echo "   oDefault     : ${oDefault}"
    echo "   oHideDefault : ${oHideDefault}"
    echo "   oHideValues  : ${oHideValues}"
    echo "   oIgnoreCase  : ${oIgnoreCase}"
    echo "   oLowerCase   : ${oLowerCase}"
    echo "   oNoTrim      : ${oNoTrim}"
    echo "   oUpperCase   : ${oUpperCase}"
    echo "   oRequired    : ${oRequired}"
    echo ""
  fi

  [ -n "${oDefault}" ] && local defaultValue="${oDefault:8}"

  local promptMsg="${zMsg}"
  [ -z "${oHideValues}" ] && [ -n "${zValues}" ] && local promptMsg="${promptMsg} <${zValues}>"
  [ -z "${oHideDefault}" ] && [ -n "${defaultValue}" ] && local promptMsg="${promptMsg} [${defaultValue}]"

  while :
  do
    read -p "${promptMsg}: " ${zVar}

    local varValue="${!zVar}"
    [ -n "${varValue}" ] && [ -z "${oNoTrim}" ] && local varValue="$(echo "${varValue}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "${varValue}" ] && [ -n "${defaultValue}" ] &&  local varValue="${defaultValue}"
    [ -n "${varValue}" ] && [ -n "${oLowerCase}" ] && local varValue="${varValue,,}"
    [ -n "${varValue}" ] && [ -n "${oUpperCase}" ] && local varValue="${varValue^^}"
    envVarSet "${zVar}" "${varValue}"

    envVarValidate "${zVar}" "${zValues}" "${oDebug}|${oIgnoreCase}|${oRequired}"
    [ -z "${envVarValidate_result}" ] && break
    echo "${envVarValidate_result}"
  done
}

fi