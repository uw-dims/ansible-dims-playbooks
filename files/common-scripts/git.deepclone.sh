#!/bin/bash
#
# vim: set ts=4 sw=4 tw=0 et :
#
# This script was derived from the blog post
# http://stevelorek.com/how-to-shrink-a-git-repository.html

for branch in `git branch -a | grep remotes | grep -v HEAD | grep -v master`; do
    git branch --track ${branch##*/} $branch
done
exit $?
