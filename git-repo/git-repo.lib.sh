#!/bin/bash

if [ -z "${GIT_REPO_LIB_SH}" ]
then

GIT_REPO_LIB_SH="loaded"

function grlError() {
  local msgPrefix="git-repo/lib"
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

[ -z "${WORKSPACE_BASE_LIB_SH}" ] && grlError "WORKSPACE_BASE_LIB_SH not defined"

wsSourceFile "${WORKSPACE_LIB_DIR}/text.lib.sh"

function gitActionClone() {
    if [ -d "${itemRepoDir}" ]
    then
      echo "  + already exists"
    else
      mkdir -p "${itemRepoDir}"
      [ $? -ne 0 ] && grlError "gitActionClone" "Failed to create, ${itemRepoDir}"
      echo "  + created"
    fi

    wsCurrentDir "${itemRepoDir}"

    if [ -d ".git" ]
    then
      echo "  + .git já existe"
    else
      git clone --no-checkout "${itemRepoUrl}" .
      [ $? -ne 0 ] && grlError "gitActionClone" "Failed to clone repository"

      git checkout "${itemRepoBranch}"
      [ $? -ne 0 ] && grlError "gitActionClone" "Failed to select branch, ${itemRepoBranch}"
    fi

    if [ -n "${pPostClone}" ]
    then
      if  [ -f "post-clone/setup.sh" ]
      then
        post-clone/setup.sh ${pEnvironment}
        [ $? -ne 0 ] && grlError "gitActionClone" "Failed to run post-clone/setup"
      fi
      if [ -n "${itemRepoPostClone}" ]
      then
        eval ${itemRepoPostClone}
        exitCode=$?
        [ $exitCode -eq 0 ] || grlError "gitActionClone" "exit-code(${exitCode}), Failed to run itemRepoPostClone: ${itemRepoPostClone}"
      fi
    fi
}

function gitActionPull() {
    wsCurrentDir "${itemRepoDir}"
    [ ! -d ".git" ] && echo "  ! .git not found" && return
    git pull
    if [ $? -ne 0 ]
    then
      grlError "gitActionPull" "Failed to update repository"
    fi
    if [ "${itemRepoDir}" != '.' ] && [ -x "./git-repo" ] && [ -f ".git-repo/git-repo.env.sh" ]
    then
      ./git-repo pull --no-current
    fi
}

function gitActionStatus() {
    wsCurrentDir "${itemRepoDir}"
    [ ! -d ".git" ] && echo "  ! .git not found" && return
    git status
    if [ $? -ne 0 ]
    then
      grlError "gitActionStatus" "Failed to update repository"
    fi
    if [ "${itemRepoDir}" != '.' ] && [ -x "./git-repo" ] && [ -f ".git-repo/git-repo.env.sh" ]
    then
      ./git-repo status --no-current
    fi
}

function gitAction() {
  [ -z "${GIT_BASE_DIR}" ] && grlError "gitAction" "GIT_BASE_DIR not defined"
  [ -z "${pAction}" ] && grlError "gitAction" "Parameter not defined, pAction"

  local item=""

  if [ "${pAction}" == "pull" ] || [ "${pAction}" == "status" ]
  then
    if [ $# -gt 0 ]
    then
      local list=""
      while [ $# -gt 0 ]
      do
        local item="$(text_trim "$1")" && shift
        if [ -n "${item}" ]
        then
          [ -n "${list}" ] && local list="${list}"$'\n'
          local list="${list}${item}"
        fi
      done
      REPO_LIST="${list}"
      unset list
    fi
  fi
  [ $# -gt 0 ] && grlError "Too many parameters, $@"

  IFS=$'\n'
  for item in ${REPO_LIST}
  do
    if [ "${item:0:1}" == "#" ] || [ "${item:0:1}" == ";" ]
    then
      echo ""
      wsMsg "gitAction" "${item}"
      wsMsg "gitAction" "  + ignored"
      item=""
    fi
    [ -z "${item}" ] && continue

    pipedItem="${item}"
    [[ "${pipedItem}" == *'|'* ]] || pipedItem="${pipedItem}|"

    itemRepoDir="$(echo "${pipedItem}" | cut -d'|' -f1)"
    itemRepoUrl="$(echo "${pipedItem}" | cut -d'|' -f2)"
    itemRepoBranch="$(echo "${pipedItem}" | cut -d'|' -f3)"
    itemRepoPostClone="$(echo "${pipedItem}" | cut -d'|' -f4-)"

    [ "${itemRepoBranch}" == "{{ENVIRONMENT}}" ] && local itemRepoBranch="${pEnvironment}"

    [ -z "${itemRepoDir}" ] && grlError "gitAction" "Value not defined : itemRepoDir, item: '${item}'"
    if [ "${pAction}" == "clone" ]
    then
      [ -z "${itemRepoUrl}" ] && grlError "gitAction" "Value not defined : itemRepoUrl, item: '${item}'"
      [ -z "${itemRepoBranch}" ] && grlError "gitAction" "Value not defined : itemRepoBranch, item: '${item}'"
    fi

    wsCurrentDir "${GIT_BASE_DIR}"

    echo ""
    [ -n "${itemRepoUrl}" ]       && echo "URL        : ${itemRepoUrl}"
    [ -n "${itemRepoBranch}" ]    && echo "Branch     : ${itemRepoBranch}"
    [ -n "${GIT_BASE_DIR}" ]      && echo "Base       : ${GIT_BASE_DIR}"
    [ -n "${itemRepoDir}" ]       && echo "Directory  : ${itemRepoDir}"
    [ -n "${itemRepoPostClone}" ] && echo "post-clone : ${itemRepoPostClone}"

    [ "${pAction}" == "clone" ] && gitActionClone
    [ "${pAction}" == "pull" ] && gitActionPull
    [ "${pAction}" == "status" ] && gitActionStatus

    unset itemRepoDir itemRepoUrl itemRepoBranch 
  done
  unset IFS
}

fi