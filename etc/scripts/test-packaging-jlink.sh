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

mvn ${MAVEN_ARGS} --version

# populate cache
if [ "${PIPELINE}" = "true" ] ; then
  mvn ${MAVEN_ARGS} -f ${WS_DIR}/pom.xml validate
fi

# Prime build all native-image tests
mvn ${MAVEN_ARGS} \
  -f ${WS_DIR}/tests/integration/native-image/pom.xml \
  install

# Build jlink images
# mp-2 fails because of https://github.com/oracle/helidon-build-tools/issues/478
for i in "se-1" "mp-1" "mp-3"; do
    mvn ${MAVEN_ARGS} \
      -f ${WS_DIR}/tests/integration/native-image/${i}/pom.xml \
      -Pjlink-image,staging \
      -Djlink.image.addClassDataSharingArchive=false \
      -Djlink.image.testImage=false \
      package
done

# Run tests with classpath and then module path

# Run SE-1 (does not contain module-info.java)
cd ${WS_DIR}/tests/integration/native-image/se-1
jri_dir=${WS_DIR}/tests/integration/native-image/se-1/target/helidon-tests-native-image-se-1-jri

# Classpath
${jri_dir}/bin/start --test

# Run MP-1
cd ${WS_DIR}/tests/integration/native-image/mp-1
jri_dir=${WS_DIR}/tests/integration/native-image/mp-1/target/helidon-tests-native-image-mp-1-jri

# Classpath
${jri_dir}/bin/start

# Module Path
${jri_dir}/bin/java \
  --module-path ${jri_dir}/app/helidon-tests-native-image-mp-1.jar:${jri_dir}/app/libs \
  --module helidon.tests.nimage.mp/io.helidon.tests.integration.nativeimage.mp1.Mp1Main

# Run MP-3 (just start and stop)
cd ${WS_DIR}/tests/integration/native-image/mp-3
jri_dir=${WS_DIR}/tests/integration/native-image/mp-3/target/helidon-tests-native-image-mp-3-jri

# Classpath
${jri_dir}/bin/start --test

# Module Path
${jri_dir}/bin/java -Dexit.on.started=! \
  --module-path ${jri_dir}/app/helidon-tests-native-image-mp-3.jar:${jri_dir}/app/libs \
  --add-modules helidon.tests.nimage.quickstartmp \
  --module io.helidon.microprofile.cdi/io.helidon.microprofile.cdi.Main
