#!/bin/bash

if [ -z "${SAIL_TRIGGERS_LIB_SH}" ]
then

SAIL_TRIGGERS_LIB_SH="loaded"

function triggersError() {
    echo "triggers.lib.sh | $@"
    exit 1
}

function triggersTemplateFile() {
    local zFile="$1" && shift
    local zSource="$1" && shift

    [ -z "${zFile}" ] && triggersError "triggersTemplateFile(): Parameter not supplied, zFile"
    [ -z "${zSource}" ] && triggersError "triggersTemplateFile(): Parameter not supplied, zSource"
    [ ! -f "${zSource}" ] && triggersError "triggersTemplateFile(): File not found, ${zSource}"

    echo "triggersTemplateFile | ${zFile}"
    cat "${zSource}" | \
      sed "s/{{PHP_VERSION}}/${PHP_VERSION}/g" \
      > "${zFile}"
}

[ -n "${SAIL_DIR}" ] || triggersError "SAIL_DIR not defined"
[ -n "${SAIL_DOCKER_DIR}" ] || triggersError "SAIL_DOCKER_DIR not defined"

fi