#!/bin/bash -ex
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

graalvm
check_native-image

mvn ${MAVEN_ARGS} --version

echo "GRAALVM_HOME=${GRAALVM_HOME}";
${GRAALVM_HOME}/bin/native-image --version;

# populate cache
mvn ${MAVEN_ARGS} -f ${WS_DIR}/pom.xml validate

# Prime build all native-image tests
mvn ${MAVEN_ARGS} \
  -f ${WS_DIR}/tests/integration/native-image/pom.xml \
  install

# Build native images
# mp-2 is too big, waiting for more memory
for i in "se-1" "mp-1" "mp-3"; do
    mvn ${MAVEN_ARGS} \
      -f ${WS_DIR}/tests/integration/native-image/${i}/pom.xml \
      -Pnative-image \
      package
done

# Run this one because it has no pre-reqs and self-tests
# Uses relative path to read configuration
cd ${WS_DIR}/tests/integration/native-image/mp-1
${WS_DIR}/tests/integration/native-image/mp-1/target/helidon-tests-native-image-mp-1
