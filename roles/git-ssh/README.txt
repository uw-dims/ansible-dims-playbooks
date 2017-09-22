This role implements a Git-over-SSH repository serving account
named "git" with:

o Git command support

o Modular Git "post-receive" hook support to drive continuous
  integration/continuous delivery via Jenkins and Ansible


Git hooks
---------

See http://cweiske.de/tagebuch/gitorious-post-receive-hook.htm
and http://qugstart.com/blog/git-and-svn/adding-git-email-notifications-via-post-receive-hook/

May need to replace with https://github.com/mhagger/git-multimail/blob/master/git-multimail/README.migrate-from-post-receive-email
