#!/bin/bash
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

[ -h "${0}" ] && readonly SCRIPT_PATH="$(readlink "${0}")" || readonly SCRIPT_PATH="${0}"
. $(dirname -- "${SCRIPT_PATH}")/includes/pipeline-env.sh "${SCRIPT_PATH}" '../..'
error_trap_setup

usage(){
    cat <<EOF

DESCRIPTION: Helidon Release Script

USAGE:

$(basename ${0}) [ --build-number=N ] CMD

  --version=V
        Override the version to use.
        This trumps --build-number=N

  --help
        Prints the usage and exits.

  CMD:

    update_version
        Update the version in the workspace

    release_build
        Perform a release build
        This will create a local branch, deploy artifacts and push a tag

EOF
}

# parse command line args
ARGS=( "${@}" )
for ((i=0;i<${#ARGS[@]};i++))
{
  ARG=${ARGS[${i}]}
  case ${ARG} in
  "--version="*)
    VERSION=${ARG#*=}
    ;;
  "--help")
    usage
    exit 0
    ;;
  *)
    if [ "${ARG}" = "update_version" ] || [ "${ARG}" = "release_build" ] ; then
      readonly COMMAND="${ARG}"
    else
      die "ERROR: unknown argument: ${ARG}"
    fi
    ;;
  esac
}

if [ -z "${COMMAND}" ] ; then
  echo "ERROR: no command provided"
  usage
  exit 1
fi

# Hooks for version substitution work
readonly PREPARE_HOOKS=( )

# Hooks for deployment work
readonly PERFORM_HOOKS=( )

# Resolve FULL_VERSION
if [ -z "${VERSION+x}" ]; then

  # get maven version
  MVN_VERSION=$(mvn ${MAVEN_ARGS} \
    -q \
    -f ${WS_DIR}/pom.xml \
    -Dexec.executable="echo" \
    -Dexec.args="\${project.version}" \
    --non-recursive \
    org.codehaus.mojo:exec-maven-plugin:1.3.1:exec)

  # strip qualifier
  readonly VERSION="${MVN_VERSION%-*}"
  readonly FULL_VERSION="${VERSION}"
else
  readonly FULL_VERSION="${VERSION}"
fi

export FULL_VERSION
printf "\n%s: FULL_VERSION=%s\n\n" "$(basename ${0})" "${FULL_VERSION}"

update_version(){
  # Update version
  mvn ${MAVEN_ARGS} \
    -f ${WS_DIR}/parent/pom.xml versions:set \
    -DgenerateBackupPoms=false \
    -DnewVersion="${FULL_VERSION}" \
    -Dproperty=helidon.version \
    -DprocessAllModules=true \
    versions:set-property

  # Hack to update helidon.version
  for pom in $(grep -E "<helidon.version>.*</helidon.version>" -r . --include pom.xml | cut -d ':' -f 1 | sort | uniq )
  do
    sed -e s@'<helidon.version>.*</helidon.version>'@"<helidon.version>${FULL_VERSION}</helidon.version>"@g ${pom} > ${pom}.tmp
    mv ${pom}.tmp ${pom}
  done

  # Hack to update helidon.version in build.gradle files
  for bfile in $(grep -E "helidonversion = .*" -r . --include build.gradle | cut -d ':' -f 1 | sort | uniq )
  do
      sed -e s@'helidonversion = .*'@"helidonversion = \'${FULL_VERSION}\'"@g ${bfile} > ${bfile}.tmp
      mv ${bfile}.tmp ${bfile}
  done

  # Invoke prepare hook
  if [ ${#PREPARE_HOOKS[*]} -gt 0 ]; then
      for prepare_hook in ${PREPARE_HOOKS[*]} ; do
          bash "${prepare_hook}"
      done
  fi
}

readonly OSSRH_STAGING="https://oss.sonatype.org/service/local/staging"
release_site(){
  [ -n "${STAGING_REPO_ID}" ] \
    && readonly MAVEN_REPO_URL="${OSSRH_STAGING}/deployByRepositoryId/${STAGING_REPO_ID}/" \
    || readonly MAVEN_REPO_URL="${OSSRH_STAGING}/deploy/maven2/"

  # Generate site
  mvn ${MAVEN_ARGS} site

  # Sign site jar
  gpg -ab ${WS_DIR}/target/helidon-project-${FULL_VERSION}-site.jar

  # Deploy site.jar and signature file explicitly using deploy-file
  mvn ${MAVEN_ARGS} \
    -Dfile="${WS_DIR}/target/helidon-project-${FULL_VERSION}-site.jar" \
    -Dfiles="${WS_DIR}/target/helidon-project-${FULL_VERSION}-site.jar.asc" \
    -Dclassifier="site" \
    -Dclassifiers="site" \
    -Dtypes="jar.asc" \
    -DgeneratePom="false" \
    -DgroupId="io.helidon" \
    -DartifactId="helidon-project" \
    -Dversion="${FULL_VERSION}" \
    -Durl="${MAVEN_REPO_URL}" \
    -DrepositoryId="ossrh" \
    -DretryFailedDeploymentCount="10" \
    deploy:deploy-file
}

release_build(){
  local GIT_BRANCH GIT_REMOTE STAGING_REPO_ID STAGING_DESC

  # Do the release work in a branch
  GIT_BRANCH="release/${FULL_VERSION}"
  git branch -D "${GIT_BRANCH}" > /dev/null 2>&1 || true
  git checkout -b "${GIT_BRANCH}"

  # Invoke update_version
  update_version

  # Update scm/tag entry in the parent pom
  sed -e s@'<tag>HEAD</tag>'@"<tag>${FULL_VERSION}</tag>"@g parent/pom.xml > parent/pom.xml.tmp
  mv parent/pom.xml.tmp parent/pom.xml

  # Git user info
  git config user.email || git config --global user.email "info@helidon.io"
  git config user.name || git config --global user.name "Helidon Robot"

  # Commit version changes
  git commit -a -m "Release ${FULL_VERSION} [ci skip]"

  # Create the nexus staging repository
  STAGING_DESC="Helidon v${FULL_VERSION}"
  mvn ${MAVEN_ARGS} \
    -DstagingProfileId="6026dab46eed94" \
    -DstagingDescription="${STAGING_DESC}" \
    nexus-staging:rc-open

  STAGING_REPO_ID=$(mvn ${MAVEN_ARGS} nexus-staging:rc-list | \
    grep -E "^[0-9:,]*[ ]?\[INFO\] iohelidon\-[0-9]+[ ]+OPEN[ ]+${STAGING_DESC}" | \
    awk '{print $2" "$3}' | \
    sed -e s@'\[INFO\] '@@g -e s@'OPEN'@@g | \
    head -1)
  echo "Nexus staging repository ID: ${STAGING_REPO_ID}"

  # Perform deployment
  mvn ${MAVEN_ARGS} clean deploy \
    -Prelease,archetypes \
    -DskipTests \
    -DstagingRepositoryId="${STAGING_REPO_ID}" \
    -DretryFailedDeploymentCount="10"

  # Invoke perform hooks
  if [ ${#PERFORM_HOOKS[*]} -gt 0 ]; then
    for perform_hook in ${PERFORM_HOOKS[*]} ; do
      bash "${perform_hook}"
    done
  fi

  # Release site (documentation, javadocs)
  release_site

  # Close the nexus staging repository
  mvn ${MAVEN_ARGS} nexus-staging:rc-close \
    -DstagingRepositoryId="${STAGING_REPO_ID}" \
    -DstagingDescription="${STAGING_DESC}"

  # Create and push a git tag
  GIT_REMOTE=$(git config --get remote.origin.url | \
      sed "s,https://\([^/]*\)/,git@\1:,")

  git remote add release "${GIT_REMOTE}" > /dev/null 2>&1 || \
  git remote set-url release "${GIT_REMOTE}"

  git tag -f "${FULL_VERSION}"
  git push --force release refs/tags/"${FULL_VERSION}":refs/tags/"${FULL_VERSION}"
}

# Invoke command
${COMMAND}
