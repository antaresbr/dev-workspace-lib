#!/bin/bash

if [ -z "${SAIL_ENV_SH}" ]
then

SAIL_ENV_SH="loaded"

sailSourceFile "${SAIL_DIR}/.env.sail.default"
[ -f "${SAIL_DIR}/.env.sail" ] && sailSourceFile "${SAIL_DIR}/.env.sail"

[ -z "${SAIL_PROJECT}" ] && sailError "SAIL_PROJECT not defined"
[ -z "${SAIL_ENV}" ] && sailError "SAIL_ENV not defined"
[ -z "${COMPOSE_PROJECT_NAME}" ] && sailError "COMPOSE_PROJECT_NAME not defined"
[ -z "${SERVER_ENVIRONMENT}" ] && sailError "SERVER_ENVIRONMENT not defined"

export SAIL_PROJECT
export SAIL_SUBPROJECT
export SAIL_ENV
export COMPOSE_PROJECT_NAME
export SERVER_ENVIRONMENT

fi