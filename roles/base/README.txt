This role is an attempt to tease out the basic configuration tasks
that should be applied to *all* DIMS related hosts. This is not
exactly the same as either the "base-os" role or "common" role
that were originally created for use in the DIMS project, but is
more like a combination of the two. 

See the "base" role that is used by the Fedora Project for more
on how this role should work.

http://infrastructure.fedoraproject.org/cgit/ansible.git/tree/roles/base

As they put it:

  "This role is the base setup for all our machines. 

   If there's something that shouldn't be run on every single 
   machine, it should be in another role."

