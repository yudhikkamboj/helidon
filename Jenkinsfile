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

pipeline {
  agent {
    label 'linux'
  }
  options {
    skipDefaultCheckout()
    parallelsAlwaysFailFast()
  }
  environment {
    NPM_CONFIG_REGISTRY = credentials('npm-registry')
  }
  stages {
    stage('default-pipeline') {
      steps {
        script {
          sayHello()
          stages = [
            name: 'build',
            task: { sh './etc/scripts/build.sh' },
            saveCache: true,
            downstreams: [
              [ name: 'unit-tests',         task: { sh './etc/scripts/test-unit.sh' },                 loadCache: true, hasTests: true ],
              [ name: 'integration-tests',  task: { sh './etc/scripts/test-integ.sh' },                loadCache: true, hasTests: true ],
              [ name: 'native-image-tests', task: { sh './etc/scripts/test-integ-native-image.sh' }, loadCache: true, hasTests: true ],
              [ name: 'tcks',               task: { sh './etc/scripts/tcks.sh' },                    loadCache: true, hasTests: true ],
              [ name: 'javadocs',           task: { sh './etc/scripts/javadocs.sh' },                loadCache: true ],
              [ name: 'spotbugs',           task: { sh './etc/scripts/spotbugs.sh' },                loadCache: true ],
              [ name: 'site',               task: { sh './etc/scripts/site.sh' },                    loadCache: true ],
              [ name: 'archetypes',         task: { sh './etc/scripts/archetypes.sh' },              loadCache: true ]]
            ],
            [ name: 'copyright',  task: { sh './etc/scripts/copyright.sh' }],
            [ name: 'checkstyle', task: { sh './etc/scripts/checkstyle.sh' }])
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

def sayHello(){
  println 'hello'
}
def runParallel(stages) {
  parallel(stages.collectEntries {
    if (!is.task) {
      return [:]
    }
    name = it.name ?: 'unnamed-stage'
    return [ name: {
      node(it.label ?: 'linux') {
        stage(name) {
          retry(3) {
            checkout scm
          }
          if (Boolean.valueOf(it.loadCache)) {
            unstash 'build-cache'
          }
          try {
            it.task()
            if (it.downstreams) {
              runParallel(it.downstreams)
            }
            if (Boolean.valueOf(it.saveCache)) {
              stash name: 'build-cache', includes: 'target/build-cache.tar'
            }
          } finally {
            if (Boolean.valueOf(it.archiveTests)) {
              archiveArtifacts artifacts: '**/target/surefire-reports/*.txt, **/target/failsafe-reports/*.txt'
              junit testResults: '**/target/surefire-reports/*.xml,**/target/failsafe-reports/*.xml'
            }
          }
        }
      }
    }]
  })
}