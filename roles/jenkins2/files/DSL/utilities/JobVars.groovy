package utilities
// Used by DSL Plugin
// Forum: https://groups.google.com/forum/#!forum/job-dsl-plugin
// Docs: https://github.com/jenkinsci/job-dsl-plugin/wiki

class JobVars {

  public static developBranch = 'develop'
  public static masterBranch = 'master'
  public static gitUrl = 'git@git.prisem.washington.edu:/opt/git/'
  public static dslRepo = 'dims-ci-utils'
  public static dslBranch = developBranch
  public static jobScriptsRepo = 'dims-ci-utils'
  public static jobScriptsBranch = developBranch
  public static jobScriptsRepoUrl = gitUrl + jobScriptsRepo + '.git'
  public static jobScriptsPath = jobScriptsRepo + '/jenkins/job-scripts/'

  public static defaultAnsibleBranch = developBranch
  public static defaultInventoryBranch = developBranch

  public static docHost = 'u12-dev-svr-1.prisem.washington.edu'
  public static docDest = '/opt/dims/docs'
  public static docUrl = 'https://'+docHost+':8443/docs'

  public static branchesToBuild = ['master', 'develop'] as List
  public static ansibleBranchesToBuild = ['master', 'develop']

  // For build type jobs, you don't need to specify the script that
  // packages the artifact - that is done automatically as the last
  // build step. Add other scripts you want to run (such as test) to
  // the scripts array.
  public static repoJobs = [
    [
      repo: 'ipgrep',
      type: 'build',
      description: '''Build ipgrep.git repo contents and package.
          Call downstream job to deploy''',
      scripts:[
        'jenkins.ipgrep-prepare'
      ],
      downstream: 'ipgrep-deploy'

    ], [
      repo: 'prisem',
      type: 'build',
      description: '''Build prisem.git repo contents and package.
          Call downstream job to deploy''',
      downstream: 'prisem-deploy'

    ], [
      repo: 'ansible-playbooks',
      type: 'build',
      description: 'Build ansible-playbooks.git repo contents and package.'
    ]
  ]

  public static adhocJobs = [
    [
      type: 'parameterized',
      name: 'dims-docs-deploy',
      description: 'Job to build and deploy a set of DIMS system documentation',
      parameters: [
        [ name: 'REPO', type: 'stringParam', defaults: '', desc: '' ],
        [ name: 'REPO', type: 'stringParam', defaults: '', desc: 'Repository to build' ],
        [ name: 'BRANCH', type: 'stringParam', defaults: '', desc: 'Branch of the repo to use' ],
        [ name: 'DOCPATH', type: 'stringParam', defaults: '.', desc: 'Path to the doc Makefile from repo root' ],
        [ name: 'DOCTYPE', type: 'stringParam', defaults: 'html', desc: 'Type of document to build - html or pdf' ],
        [ name: 'DOCDELETE', type: 'stringParam', defaults: 'false', desc: 'True if the documentation is to be deleted' ],
        [ name: 'DOCHOST', type: 'stringParam', defaults: docHost, desc: 'Host to receive the docs' ],
        [ name: 'DOCDEST', type: 'stringParam', defaults: docDest, desc: 'Root destination on host to deploy the docs' ],
        [ name: 'DOCURL', type: 'stringParam', defaults: docUrl, desc: 'URL to documentation root directory' ]
      ],
      scripts: [ 'jenkins.dims-docs-deploy '],
      virtualEnv: 'dimsenv'
    ]

  ]
  

}