#!/bin/bash

[ "${BASH_SOURCE[0]}" -ef "$0" ] && echo "$(basename "$0") | ERROR: This file must be sourced" && exit 1

if [ -z "${POST_CLONE_SETUP_LIB_SH}" ]
then

POST_CLONE_SETUP_LIB_SH="loaded"

function pcslError() {
  local msgPrefix="setup-lib"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  pcsError "${msgPrefix}" "$@"
  exit 1
}

[ -n "${BASE_DIR}" ] || pcslError "WORKSPACE_BASE_LIB_SH not defined"

WORKSPACE_LIB_DIR="${BASE_DIR}/.workspace-lib"
if [ ! -d "${WORKSPACE_LIB_DIR}" ]
then
  mkdir "${WORKSPACE_LIB_DIR}"
  [ $? -eq 0 ] || pcslError "Fail to create directory, ${WORKSPACE_LIB_DIR}"
  chmod 755 "${WORKSPACE_LIB_DIR}"
fi
if [ ! -d "${WORKSPACE_LIB_DIR}/.git" ]
then
  repoToClone="https://github.com/antaresbr/dev-workspace-lib.git"
  echo ""
  git clone "${repoToClone}" "${WORKSPACE_LIB_DIR}"
  [ $? -ne 0 ] && pcslError "Failed to clone repository, ${repoToClone}"
fi

libFile="${WORKSPACE_LIB_DIR}/base.lib.sh"
[ ! -f "${libFile}" ] && pcslError "File not found: ${libFile}\n"
source "${libFile}"
[ $? -ne 0 ] && pcslError "Fail to source file: ${libFile}\n"
unset libFile
wsSourceFile "${WORKSPACE_LIB_DIR}/env-var.lib.sh"

[ ! -x "${WORKSPACE_LIB_DIR}/git-repo/git-repo.sh" ] && chmod +x "${WORKSPACE_LIB_DIR}/git-repo/git-repo.sh"
[ ! -x "${WORKSPACE_LIB_DIR}/sail/sail.sh" ] && chmod +x "${WORKSPACE_LIB_DIR}/sail/sail.sh"

wsCreateLink "../.workspace-lib/post-clone" "${SCRIPT_DIR}/lib"
wsCreateLink ".workspace-lib/git-repo/git-repo.sh" "${BASE_DIR}/git-repo"

wsSourceFile "${SCRIPT_DIR}/lib/post-clone.lib.sh"

pEnvironment="$1" && shift
[ -z "${pEnvironment}" ] && pcslError "Parameter not supplied, pEnvironment"
[ $# -gt 0 ] && pcslError "Too many parameters, $@"

cd "${BASE_DIR}"
[ $? -ne 0 ] && pcslError "Fail to access ${BASE_DIR}"

echo ""
echo "Get SUDO access"
sudo ls -alF > /dev/null
[ $? -eq 0 ] || pcslError "Fail to get SUDO access"

if [ -f ".git-repo/git-repo.env.sh" ]
then
  ./git-repo clone --post-clone --environment ${pEnvironment}
  [ $? -ne 0 ] && pcslError "Fail running git-repo"
fi

wsSourceFile "${SCRIPT_DIR}/setup.local.sh"
wsSourceFileIfExists "${SCRIPT_DIR}/setup.local.env.default"

fi
