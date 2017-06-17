package utilities

class JobUtilities {

  static void addScm(def job, def directory, def gitBranch, def repoUrl, def isRemotePoll) {
    job.with {
      scm {
        git {
          remote {
            url(repoUrl)
          }
          relativeTargetDir(directory)
          branch(gitBranch)
          remotePoll(isRemotePoll)
        }
      }
    }
  }

  static void addScmTriggers(def job) {
    job.with {
      triggers {
        scm("")
      }
    }
  }

  static void addStandardComponents(def job) {
    job.with {
      logRotator(-1, 15, -1, -5)
      wrappers {
          preBuildCleanup()
          buildName("\${GIT_REVISION, length=7}_\${BUILD_NUMBER}")
      }
      environmentVariables {
        keepSystemVariables(true)
        keepBuildVariables(true)
      }
      label('master')
    }
  }

  static void addPostNotify(def job) {
    job.with {
      publishers {
        downstreamParameterized {
          trigger('post-notify', 'ALWAYS') {
            predefinedProps([
              BUILD_TAG: "\$BUILD_TAG", 
              BUILD_URL: "\$BUILD_URL",
              BUILD_DISPLAY_NAME: "\$BUILD_DISPLAY_NAME"])
          }
        }
      }
    }
  }

  static void addArchiveArtifacts(def job, def artifact) {
    job.with {
      publishers {
        archiveArtifacts(artifact)
      }
    }
  }

  static void addDownstream(def job, def downstream) {
    job.with {
      publishers {
        downstreamParameterized {
          trigger(downstream, 'SUCCESS') {
            predefinedProps([
              BUILD_TAG: "\$BUILD_TAG", 
              BUILD_URL: "\$BUILD_URL",
              BUILD_DISPLAY_NAME: "\$BUILD_DISPLAY_NAME"])
          }
        }
      }
    }
  }

  static void addCopyArtifacts(def job, def upstream, def artifact) {
    job.with  {
      steps {
        copyArtifacts(upstream, artifact) {
          upstreamBuild(true)
        }
      }
    }
  }

  static void addPublishArtifacts(def job) {
    job.with {
      publishers {
        postBuildScripts {
          steps {
            shell('/opt/dims/bin/jenkins.saveartifact && /opt/dims/bin/jenkins.artifactsrsync')
          }
        }
      }
    }
  }

  static void addRunInDimsenv(def job, def command) {
    job.with {
      configure { project ->
        project / 'builders' << 'jenkins.plugins.shiningpanda.builders.CustomPythonBuilder' {
          home('/opt/dims/envs/dimsenv')
          nature('shell')
          command(command)
        }
      }
    }
  }

  static void addParameters(def job, def parameters) {
    parameters.each { 
      job.with parameters {
        it.type(it.name, it.defaults, it.desc)
      }
    }
  }
}