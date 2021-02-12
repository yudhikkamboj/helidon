/*
 * Copyright (c) 2020, 2021 Oracle and/or its affiliates.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


def t(closure) {
  return {
    try { closure() } finally {
      archiveArtifacts artifacts: "**/target/surefire-reports/*.txt, **/target/failsafe-reports/*.txt"
      junit testResults: '**/target/surefire-reports/*.xml,**/target/failsafe-reports/*.xml'
    }
  }
}
def r(script) {
  return { sh script }
}
def s(name, Closure ...closures) {
  return [ name: stage(name) { steps { closures.each { it() } } } ]
}
def p(...stages) {
  return { parallel stages.collectEntries { it } }
}

pipeline {
  agent {
    label "linux"
  }
  options {
    parallelsAlwaysFailFast()
  }
  environment {
    NPM_CONFIG_REGISTRY = credentials('npm-registry')
  }
  stages {
    stage('default-pipeline') {
      steps {
        script {
          p(
            s('build',
              r('./etc/scripts/build.sh'),
              p(
                s('unit-tests', t(r('./etc/scripts/test-unit.sh'))),
                s('integration-tests', t(r('./etc/scripts/test-integ.sh'))),
                s('native-image-tests', t(r('./etc/scripts/test-integ-native-image.sh'))),
                s('tcks', t(r('./etc/scripts/tcks.sh'))),
                s('javadocs', r('./etc/scripts/javadocs.sh')),
                s('spotbugs', r('./etc/scripts/spotbugs.sh')),
                s('javadocs', r('./etc/scripts/javadocs.sh')),
                s('site', r('./etc/scripts/site.sh')),
                s('archetypes', r('./etc/scripts/archetypes.sh'))
              ),
            s('copyright', r('./etc/scripts/copyright.sh')),
            s('checkstyle', r('./etc/scripts/checkstyle.sh')))()
        }
      }
    }
    stage('release-pipeline') {
      when { branch '**/release-*' }
      environment {
        GITHUB_SSH_KEY = credentials('helidonrobot-github-ssh-private-key')
        MAVEN_SETTINGS_FILE = credentials('helidonrobot-maven-settings-ossrh')
        GPG_PUBLIC_KEY = credentials('helidon-gpg-public-key')
        GPG_PRIVATE_KEY = credentials('helidon-gpg-private-key')
        GPG_PASSPHRASE = credentials('helidon-gpg-passphrase')
      }
      steps { sh './etc/scripts/release.sh release_build' }
    }
  }
}
