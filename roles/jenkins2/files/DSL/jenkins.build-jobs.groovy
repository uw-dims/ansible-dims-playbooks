import utilities.JobUtilities as utils
import utilities.JobVars as vars

//def defaults = new GroovyScriptEngine('.').with {
//  loadScriptByName( '/opt/dims/bin/defaults.groovy')
//}
//this.metaClass.mixin defaults


// We're going to create jobs for:
// Build jobs based upon git repos
// Deploy jobs triggered by build jobs
// AdHoc jobs not based upon a repo

// First, build all jobs based upon our git repos
vars.branchesToBuild.each { currentBranch ->
  vars.repoJobs.each { currentConfig ->

    println currentBranch

    def currentName = currentConfig.repo + '-' + currentConfig.type + '-' + currentBranch
    def currentJob = freeStyleJob(currentName)

    utils.addStandardComponents(currentJob)
    utils.addScm(currentJob, currentConfig.repo, currentBranch, 'git@git.prisem.washington.edu:/opt/git/ipgrep.git', true)
    utils.addScmTriggers(currentJob)
    utils.addPostNotify(currentJob)

    currentConfig.scripts.each { currentScript ->
      currentJob.with {
        steps {
          shell(currentScript)
        }
      }
    }
    // For a build job, package the artifact and distribute the packages
    if (currentConfig['type'] == 'build') {
      currentJob.with {
        steps {
          shell ( 'jenkins.package-artifact ' + currentConfig.repo + '-' + currentBranch)
        }
      }
      utils.addArchiveArtifacts(currentJob, currentConfig.repo + '-' + currentBranch + '.tgz')
      utils.addPublishArtifacts(currentJob)
    }

  }
}


