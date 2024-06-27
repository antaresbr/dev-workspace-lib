#!/bin/bash

if [ -z "${WORKSPACE_BASE_LIB_SH}" ]
then

WORKSPACE_BASE_LIB_SH="loaded"

WORKSPACE_LIB_DIR="$(dirname "${BASH_SOURCE[0]}")"

#-- wsMsg : Show message prefixed by script name
#   parameters
#     ...  : Texts to show
function wsMsg() {
  echo "$(basename "$0") | $@"
}


#-- wsWarn : Show warn message
#   parameters
#     ...  : Texts to show
function wsWarn() {
  local msgPrefix="$(basename "$0")"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  echo ""
  echo "${msgPrefix} | WARN: $@"
  echo ""
}


#-- wsActionWarn : Show an <pAction> warn
#   parameters
#     ...  : Texts to show
function wsActionWarn() {
  local msgPrefix="action_${pAction}"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  wsWarn "${msgPrefix}" "$@"
}


#-- wsError : Show error message and exit
#   parameters
#     ...  : Texts to show
function wsError() {
  local msgPrefix="$(basename "$0")"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  echo ""
  echo "${msgPrefix} | ERROR | $@"
  echo ""
  exit 1
}


#-- wsActionError : Show an <pAction> error message and exit
#   parameters
#     ...  : Texts to show
function wsActionError() {
  local msgPrefix="action_${pAction}"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  wsError "${msgPrefix}" "$@"
  exit 1
}


#-- wsSourceFile : Import a script file
#   parameters
#     zFile : File to be sourced
function wsSourceFile() {
  local zFile="$1"

  [ ! -f "${zFile}" ] && wsError "wsSourceFile" "File not found: ${zFile}"
  source "${zFile}"
  if [ $? -ne 0 ]
  then
    wsError "wsSourceFile" "Fail to source file: ${zFile}"
  fi
}


#-- wsSourceFileIfExists : Import a script file, if exists
#   parameters
#     zFile : File to be sourced
function wsSourceFileIfExists() {
  local zFile="$1"

  if [ -f "${zFile}" ]
  then
    wsSourceFile "$@"
  fi
}


#-- wsCurrentDir : Sets the current working directory
#   parameters
#     zDir : Target directory
function wsCurrentDir() {
    local zDir="$1" && shift
    [ -z "${zDir}" ] && wsError "wsCurrentDir" "Parameter not supplied, zDir"

    local targetDir="$(realpath "${zDir}")"

    [ ! -d "${zDir}" ] && wsError "wsCurrentDir" "Directory not found, ${zDir}"

    cd "${zDir}"
    if [ "${targetDir}" != "$(realpath "$(pwd)")" ]
    then
      wsError "wsCurrentDir" "Fail to access, ${zDir}"
    fi
}


#-- wsCreateLink : Creates a symbolic link
#   parameters
#     zTarget : Target to be linked
#     zName   : Link name
function wsCreateLink() {
  local zTarget="$1" && shift
  local zName="$1" && shift

  [ -z "${zTarget}" ] && wsError "wsCreateLink" "Parameter not supplied, zTarget"
  [ -z "${zName}" ] && wsError "wsCreateLink" "Parameter not supplied, zName"

  [ -L "${zName}" ] && [ ! -e "${zName}" ] && rm "${zName}"

  [ -e "${zName}" ] && return

  ln -s "${zTarget}" "${zName}"
  if [ $? -ne 0 ]
  then
    wsError "wsCreateLink" "Fail to link, ${zTarget} -> ${zName}"
  fi
}


#-- wsSetMode : Sets the file mode
#   parameters
#     zTarget : Target to be set
#     zMode   : Desired mode
function wsSetMode() {
  local zTarget="$1"
  local zMode="$2"

  [ -z "${zTarget}" ] && wsError "wsSetMode" "Parameter not supplied, zTarget"

  if [ -n "${zMode}" ]
  then
    chmod ${zMode} ${zTarget}
    [ $? -eq 0 ] || wsError "wsSetMode" "Fail to set the file mode, ${zMode} - ${zTarget}"
  fi
}


#-- wsTemplateFile : Templates a file
#   parameters
#     zTarget : Target file
#     zSource : Source template
#     zVars   : Custom vars to be used
function wsTemplateFile() {
  local zTarget="$1" && shift
  local zSource="$1" && shift
  local zVars="$1" && shift

  [ -z "${zTarget}" ] && wsError "wsTemplateFile" "Parameter not supplied, zTarget"
  [ -f "${zTarget}" ] && wsMsg "wsTemplateFile" "File already exists, ${zTarget}" && return

  [ -z "${zSource}" ] && [ -f "${zTarget}.template" ] && local zSource="${zTarget}.template"
  [ -z "${zSource}" ] && [ -f "${zTarget}.example" ] && local zSource="${zTarget}.example"
  [ -z "${zSource}" ] && wsError "wsTemplateFile" "Parameter not supplied, zSource"
  [ ! -f "${zSource}" ] && [ -f "$(dirname "${zTarget}")/${zSource}" ] && local zSource="$(dirname "${zTarget}")/${zSource}"
  [ ! -f "${zSource}" ] && wsError "wsTemplateFile" "Source file not found, ${zSource}"

  local wVars="${WS_TEMPLATE_FILE_VARS}"
  if [ -n "${zVars}" ]
  then
    [ -n "${wVars}" ] && local wVars="${wVars}"$'\n'
    local wVars="${wVars}${zVars}"
  fi
  echo "${wVars}" | grep "^ENVIRONMENT=" &> /dev/null
  [ $? -ne 0 ] && local wVars="${wVars}"$'\n'"ENVIRONMENT=${ENVIRONMENT}"
  echo "${wVars}" | grep "^SAIL_USERNAME=" &> /dev/null
  [ $? -ne 0 ] && local wVars="${wVars}"$'\n'"SAIL_USERNAME=${SAIL_USERNAME}"
  echo "${wVars}" | grep "^SAIL_USERID=" &> /dev/null
  [ $? -ne 0 ] && local wVars="${wVars}"$'\n'"SAIL_USERID=${SAIL_USERID}"

  if [ "${zSource:(-8)}" == ".example" ] || [ "${zSource:(-8)}" == "-example" ]
  then
    cp "${zSource}" "${zTarget}"
    [ $? -ne 0 ] && wsError "wsTemplateFile" "Fail to create file, ${zTarget}"
    IFS=$'\n'
    for varItem in ${wVars}
    do
      local varName="$(echo "${varItem}" | cut -d'=' -f 1)"
      local varValue="$(echo "${varItem}" | cut -d'=' -f 2-)"
      [ -z "${varName}" ] && continue
      sed -i "s/{{${varName}}}/$(echo "${varValue}" | sed 's|/|\\/|g')/g" "${zTarget}"
      [ $? -ne 0 ] && wsError "wsTemplateFile" "Fail to apply replacement, ${zTarget} : ${varName} => ${varValue}"
    done
    unset IFS
  else
    bash -c "${wVars} ; cat << EOF
$(<${zSource})
EOF
"     | tee "${zTarget}" > /dev/null
    [ $? -ne 0 ] && wsError "wsTemplateFile" "Fail to create file, ${zTarget}"
  fi
}


#-- wsCertifyPath : Certity path
#   parameters
#     zTarget : Target file
#     zMode   : Desired mode
function wsCertifyPath() {
  local zTarget="$1"
  local zMode="$2"

  [ -z "${zTarget}" ] && wsError "wsCertifyPath" "Parameter not supplied, zTarget"

  if [ ! -d "${zTarget}" ]
  then
    mkdir "${zTarget}"
    [ $? -ne 0 ] && wsError "wsCertifyPath" "Fail to create directory, ${zTarget}"
  fi

  setMode "${zTarget}" "${zMode}"
}


#-- wsCopyFileIfNotExists : Copy file if target does not exists
#   parameters
#     zSource : Source file
#     zTarget : Target file
#     zMode   : Desired mode
function wsCopyFileIfNotExists() {
  local zSource="$1" && shift
  local zTarget="$1" && shift
  local zMode="$1" && shift

  [ -z "${zSource}" ] && wsError "wsCopyFileIfNotExists" "Parameter not supplied, zSource"
  [ ! -f "${zSource}" ] && wsError "wsCopyFileIfNotExists" "Source file not found, ${zSource}"

  [ -z "${zTarget}" ] && wsError "wsCopyFileIfNotExists" "Parameter not supplied, zTarget"

  if [ -d "${zTarget}" ]
  then
    [ "${zTarget: -1}" == "/" ] || zTarget="${zTarget}/"
    local wTarget="${zTarget}$(basename "${zSource}")"
  else
    local wTarget="${zTarget}"
  fi

  if [ -f "${wTarget}" ]
  then
    echo "  + already exists : $(realpath "${wTarget}")"
  else
    cp -v "${zSource}" "${wTarget}"
    [ $? -ne 0 ] && exit 1

    [ -z "${zMode}" ] || setMode "${wTarget}" "${zMode}"
  fi
}

fi