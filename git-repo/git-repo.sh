#!/bin/bash

START_DIR=$(pwd)
GIT_BIN_DIR="$(dirname "$(realpath "$0")")"
GIT_BIN_DIR="$(cd "${GIT_BIN_DIR}" && pwd)"
GIT_BASE_DIR="$(dirname "$(realpath -s "$0")")"
GIT_BASE_DIR="$(cd "${GIT_BASE_DIR}" && pwd)"

function grError() {
  local msgPrefix="git-repo"
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

libFile="$(realpath "${GIT_BIN_DIR}/../base.lib.sh")"
[ ! -f "${libFile}" ] && grError "File not found, ${libFile}"
source "${libFile}"
[ $? -ne 0 ] && grError "Fail to source file, ${libFile}"
unset libFile

wsSourceFile "${GIT_BIN_DIR}/git-repo.lib.sh"

wsSourceFileIfExists "${GIT_BASE_DIR}/.git-repo/git-repo.env.sh"
[ -z "${REPO_LIST}" ] && wsSourceFileIfExists "${GIT_BASE_DIR}/workspace.env.sh"
if [ -z "${REPO_LIST}" ]
then
  echo ""
  wsMsg "${GIT_BASE_DIR}"
  wsMsg "No repository in REPO_LIST"
  echo ""
  exit 0
fi

#-- obter parâmetros

p=0
while [ ${p} -lt $# ]
do
  let "p=p+1"
  if [ "${!p}" == "--post-clone" ]
  then
    pPostClone="${!p}"
    set -- "${@:1:p-1}" "${@:p+1}"
  fi
  if [ "${!p}" == "--no-current" ]
  then
    pNoCurrent="${!p}"
    set -- "${@:1:p-1}" "${@:p+1}"
  fi
  if [ "${!p}" == "--environment" ]
  then
    pEnvironment="${@:p+1:1}"
    set -- "${@:1:p-1}" "${@:p+2}"
    if [[ "local,develop,release,production,master,main," != *"${pEnvironment},"* ]] || \
       [ -z "${pEnvironment}" ]
    then
      wsError "Invalid pEnvironment parameter, '${pEnvironment}'"
    fi
  fi
done
unset p

pAction="$1"
shift

#-- action

cd "${GIT_BASE_DIR}"

case "${pAction}" in
  'clone' | 'pull' | 'status')
    if [ "${pAction}" == "pull" -o "${pAction}" == "status" ] && [ $# -eq 0 ] && [ -z "${pNoCurrent}" ]
    then
      [ -n "${REPO_LIST}" ] && REPO_LIST=$'\n'"${REPO_LIST}"
      REPO_LIST=".${REPO_LIST}"
    fi
    gitAction $@
  ;;
  'help' | '--help')
    echo "
Use: $(basename "$0") <action> [options]

Actions:

  clone   Clone inner repositories
  pull    Update base and inner repositories
  status  View status of base and inner repositories
  help    Show this help message

Options:

  --environment   Environment: [ local | develop | release | production |master | main ]
  --post-clone    Run post-clone/setup script
"
  ;;
  *)
      grError "Invalid or not supplied action: '${pAction}'"
  ;;
esac

cd "${START_DIR}"
echo ""
