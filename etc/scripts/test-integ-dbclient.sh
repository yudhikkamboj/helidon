#!/bin/bash -e
#
# Copyright (c) 2021 Oracle and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# shellcheck disable=SC2015
[ -h "${0}" ] && readonly SCRIPT_PATH="$(readlink "${0}")" || readonly SCRIPT_PATH="${0}"
. $(dirname -- "${SCRIPT_PATH}")/includes/pipeline-env.sh "${SCRIPT_PATH}" '../..'
error_trap_setup

# Set Graal VM into JAVA_HOME and PATH (defined in includes/pipeline-env.sh)
graalvm

print_help() {
    cat <<EOF
Usage: test-integ-dbclient.sh [-hsjn] -d <database>

  -h print this help and exit
  -s execute simple tests (default when no -s, -j or -n is passed)
  -j execute remote application tests in Java VM mode
  -n execute remote application tests in native image mode
  -d <database> select database
     <database> :: mysql | pgsql
EOF
}

# Evaluate command line arguments
if [ "$#" -gt '0' ]; then
    while getopts 'hsjnd:' flag 2> /dev/null; do
        case "${flag}" in
            h) print_help && exit;;
            d) readonly FLAG_D=${OPTARG};;
            s) readonly FLAG_S='1';;
            j) readonly FLAG_J='1';;
            n) readonly FLAG_N='1';;
        esac
    done
fi

# Load database setup
if [ -n "${FLAG_D}" ]; then
    case "${FLAG_D}" in
        mysql) . ${WS_DIR}/etc/scripts/includes/mysql.sh;;
        pgsql) . ${WS_DIR}/etc/scripts/includes/pgsql.sh;;
        *)     echo 'ERROR: Unknown database name, exiting.' && exit 1;;
    esac
else
    echo 'ERROR: No database was selected, exiting.'
    exit 1
fi

# Turn simple tests on when no test was selected
[ -z "${FLAG_J}" -a -z "${FLAG_N}" -a -z "${FLAG_S}" ] && \
    readonly FLAG_S='1'

# populate cache
mvn ${MAVEN_ARGS} -f ${WS_DIR}/pom.xml validate

# Run simple JDBC tests
[ -n "${FLAG_S}" ] && \
    (cd ${WS_DIR}/tests/integration/dbclient && \
        echo mvn ${MAVEN_ARGS} \
            -P${DB_PROFILE} \
            -pl "common,jdbc" \
            -Dapp.config=${TEST_CONFIG} \
            -Ddb.user=${DB_USER} \
            -Ddb.password=${DB_PASSWORD} \
            -Ddb.url="${DB_URL}" \
             verify && \
        mvn ${MAVEN_ARGS} \
            -P${DB_PROFILE} \
            -pl "common,jdbc" \
            -Dapp.config=${TEST_CONFIG} \
            -Ddb.user=${DB_USER} \
            -Ddb.password=${DB_PASSWORD} \
            -Ddb.url="${DB_URL}" \
            verify)

# Run remote application tests in Java VM mode
[ -n "${FLAG_J}" ] && \
    (cd ${WS_DIR}/tests/integration/dbclient && \
        echo mvn ${MAVEN_ARGS} \
            -P${DB_PROFILE} \
            -Dapp.config=${TEST_CONFIG} \
            -Ddb.user=${DB_USER} \
            -Ddb.password=${DB_PASSWORD} \
            -Ddb.url="${DB_URL}" \
            -pl appl \
            verify && \
        mvn ${MAVEN_ARGS} \
            -P${DB_PROFILE} \
            -Dapp.config=${TEST_CONFIG} \
            -Ddb.user=${DB_USER} \
            -Ddb.password=${DB_PASSWORD} \
            -Ddb.url="${DB_URL}" \
            -pl appl \
            verify)

# Run remote application tests in native image mode
[ -n "${FLAG_N}" ] && \
    (cd ${WS_DIR}/tests/integration/dbclient && \
        echo mvn ${MAVEN_ARGS} \
            -P${DB_PROFILE} \
            -Pnative-image \
            -Dapp.config=${TEST_CONFIG} \
            -Ddb.user=${DB_USER} \
            -Ddb.password=${DB_PASSWORD} \
            -Ddb.url="${DB_URL}" \
            -pl appl verify && \
        mvn ${MAVEN_ARGS} \
            -P${DB_PROFILE} \
            -Pnative-image \
            -Dapp.config=${TEST_CONFIG} \
            -Ddb.user=${DB_USER} \
            -Ddb.password=${DB_PASSWORD} \
            -Ddb.url="${DB_URL}" \
            -pl appl verify)
