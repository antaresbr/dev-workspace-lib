#!/bin/bash

if [ -z "${POST_CLONE_SETUP_LIB_SH}" ]
then

POST_CLONE_SETUP_LIB_SH="loaded"

function pcslError() {
  local msgPrefix="post-clone/setup-lib"
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
  echo ""
  git clone https://github.com/antaresbr/dev-workspace-lib.git "${WORKSPACE_LIB_DIR}"
  [ $? -ne 0 ] && pcslError "Falha ao copiar projeto workspace-lib\n"
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

if [ -f ".git-repo/git-repo.env.sh" ]
then
  ./git-repo clone --post-clone --environment ${pEnvironment}
  [ $? -ne 0 ] && pcslError "Fail running git-repo"
fi

wsSourceFile "${SCRIPT_DIR}/setup.local.sh"

fi
