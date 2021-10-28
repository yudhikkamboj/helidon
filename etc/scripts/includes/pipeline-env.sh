#
# Copyright (c) 2018, 2021 Oracle and/or its affiliates.
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

###############################################################################
# Pipeline environment setup                                                  #
###############################################################################
# Shell variables: WS_DIR
# Arguments: $1 - Script path
#            $2 - cd to Helidon root directory from script path
#
# At least WS_DIR or both arguments must be passed.

die() {
  echo "${1}" ; exit 1
}

# WS_DIR variable verification.
if [ -z "${WS_DIR}" ]; then
  [ -z "${1}" ] && die "ERROR: Missing required script path, exiting" || true
  [ -z "${2}" ] && die "ERROR: Missing required cd to Helidon root directory from script path, exiting" || true
  readonly WS_DIR=$(cd $(dirname -- "${1}") ; cd "${2}" ; pwd -P)
fi

# Multiple definition protection.
if [ -n "${__PIPELINE_ENV_INCLUDED__}" ]; then
  echo "WARNING: ${WS_DIR}/etc/scripts/includes/pipeline-env.sh included multiple times."
  exit 0
fi

readonly __PIPELINE_ENV_INCLUDED__='true'
. ${WS_DIR}/etc/scripts/includes/error_handlers.sh

require_env() {
  [ -z "$(eval echo \$${1})" ] && die "ERROR: ${1} not set in the environment" || true
}

check_graalvm_home() {
  [ -z "${GRAALVM_HOME}" ] && die "ERROR: GRAALVM_HOME is not set" || true
}

graalvm() {
  check_graalvm_home
  JAVA_HOME=${GRAALVM_HOME}
  PATH="${JAVA_HOME}/bin:${PATH}"
}

check_native-image() {
  check_graalvm_home
  [ ! -x "${GRAALVM_HOME}/bin/native-image" ] && \
    die "ERROR: ${GRAALVM_HOME}/bin/native-image does not exist or is not executable"  \
    || true
}

if [ -n "${JENKINS_HOME}" ] ; then
  export PIPELINE="true"
  export JAVA_HOME="/tools/jdk-11.0.12"
  [ -z "${GRAALVM_HOME}" ] && export GRAALVM_HOME="/tools/graalvm-ce-java11-21.3.0" || true

  MAVEN_OPTS="${MAVEN_OPTS} -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"
  MAVEN_OPTS="${MAVEN_OPTS} -Dorg.slf4j.simpleLogger.showDateTime=true"
  MAVEN_OPTS="${MAVEN_OPTS} -Dorg.slf4j.simpleLogger.dateTimeFormat=HH:mm:ss,SSS"
  export MAVEN_OPTS
  export PATH="/tools/apache-maven-3.6.3/bin:${JAVA_HOME}/bin:/tools/node-v12/bin:${PATH}"

  [ -n "${GITHUB_SSH_KEY}" ] &&  export GIT_SSH_COMMAND="ssh -i ${GITHUB_SSH_KEY}" || true

  MAVEN_ARGS="${MAVEN_ARGS} -B -e -Ppipeline,ossrh-releases,ossrh-staging,staging"
  [ -n "${MAVEN_SETTINGS_FILE}" ] && MAVEN_ARGS="${MAVEN_ARGS} -s ${MAVEN_SETTINGS_FILE}" || true
  [ -n "${NPM_CONFIG_REGISTRY}" ] && MAVEN_ARGS="${MAVEN_ARGS} -Dnpm.download.root=${NPM_CONFIG_REGISTRY}/npm/-/" || true
  export MAVEN_ARGS

  [ -n "${https_proxy}" ] && [[ ! "${https_proxy}" =~ ^http:// ]] && export https_proxy="http://${https_proxy}" || true
  [ -n "${http_proxy}" ] && [[ ! "${http_proxy}" =~ ^http:// ]] && export http_proxy="http://${http_proxy}" || true
  if [ ! -e "${HOME}/.npmrc" ] ; then
      [ -n "${NPM_CONFIG_REGISTRY}" ] && echo "registry = ${NPM_CONFIG_REGISTRY}" >> ${HOME}/.npmrc || true
      [ -n "${https_proxy}" ] && echo "https-proxy = ${https_proxy}" >> ${HOME}/.npmrc || true
      [ -n "${http_proxy}" ] && echo "proxy = ${http_proxy}" >> ${HOME}/.npmrc || true
      [ -n "${NO_PROXY}" ] && echo "noproxy = ${NO_PROXY}" >> ${HOME}/.npmrc || true
  fi

  [ -n "${GPG_PUBLIC_KEY}" ]  && gpg --import --no-tty --batch ${GPG_PUBLIC_KEY} || true
  [ -n "${GPG_PRIVATE_KEY}" ] && gpg --allow-secret-key-import --import --no-tty --batch ${GPG_PRIVATE_KEY} || true
  if [ -n "${GPG_PASSPHRASE}" ] ; then
      echo "allow-preset-passphrase" >> ~/.gnupg/gpg-agent.conf
      gpg-connect-agent reloadagent /bye
      GPG_KEYGRIP=$(gpg --with-keygrip -K | grep "Keygrip" | head -1 | awk '{print $3}')
      /usr/lib/gnupg/gpg-preset-passphrase --preset "${GPG_KEYGRIP}" <<< "${GPG_PASSPHRASE}"
  fi
fi
