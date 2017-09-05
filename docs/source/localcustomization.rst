.. _localcustomization:

Customizing a Private Deployment
================================

The public Ansible playbooks in the ``ansible-dims-playbooks`` repository
are designed to be public, which means they must (by definition) not
contain real secrets. What is more, if someone wants to deploy their
own instance of DIMS subsystems, they will need to maintain their
own copies of inventory files, templates, and yes, secret files
like Ansible vault, certificates, private keys, etc.  These
files obviously can't be committed to the public repository
``master`` or ``develop`` branches.

To facilitate keeping everything above (and more files, like
backups of databases) completely separate, the ``ansible-dims-playbooks``
roles allow a second parallel repository that shares some of
same subdirectories is used. The common directories are
``files/``, ``roles/``, and ``vars/``. By convention, the
directory is named ``private-`` followed by an identifier
of your choice (e.g., ``private-devtest`` could be your
development test deployment). This location is pointed to
by the environment variable ``DIMS_PRIVATE`` and the
Ansible variable ``dims_private`` which is set in
the inventory, playbooks, or command line.

.. note::

    Some wrapper scripts will automatically set ``dims_private`` from
    the environment variable ``DIMS_PRIVATE``. There is a helper function
    in ``dims_functions.sh`` called ``get_private`` that returns the
    directory path based on the ``DIMS_PRIVATE`` environment variable
    or falling back to the ``ansible-dims-playbooks`` directory for
    a pure local development environment.

..

To facilitate creating the private customization directory repository,
the ``cookiecutter`` program can be used.

.. _cookiecutter:

Cookiecutter
------------

Cookiecutter is a command-line utility used to template project
structures. It uses Jinja2 to take generalized templates of file
names and file contents and render them to create a new, unique
directory tree.  A `popular Cookiecutter template`_, used by Cookiecutter
in their documentation, is a Python package project template.

Cookiecutter can be used to template more than Python packages and can
do so for projects using languages other than Python.

Cookiecutter documentation and examples:

   * `Latest Cookiecutter Docs`_
   * `Python Package Project Template Example`_
   * `Cookiecutter Tutorial`_

Cookiecutter is being integrated into the DIMS project as a Continuous
Integration Utility. It's command line interface, ``cookiecutter``, is
installed along with other tools used in the DIMS project in the ``dimsenv``
Python virtual environment.

.. code-block:: none

    $ which cookiecutter
    /home/dittrich/dims/envs/dimsenv/bin/cookiecutter

..

The source files used by ``cookiecutter`` can be found in
``ansible-dims-playbooks/files/cookiecutter``.

The directory ``ansible-dims-playbooks/files/cookiecutter/dims-new-repo/`` provides a
template for a new Git source code repository that contains a Sphinx
documentation directory suitable for publication on `ReadTheDocs`_.

.. _ReadTheDocs: https://readthedocs.org

.. note::

    This template is usable for a source code repository with documentation,
    but can also be used for a documentation-only repository.  If no Sphinx
    documentation is necessary, simply delete the ``docs/`` directory
    prior to making the initial commit to Git. Documenting how to use
    the repository is recommended.

..

.. _cookiecutterTopLevel:

Top Level Files and Directories
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``cookiecutter`` template directory used for creating DIMS project
Git repositories contains the following files and directories:

.. code-block:: none

    ../cookiecutter/
    ├── dims-new-repo
    ├── dims-new-repo.yml
    ├── dims-private
    └── README.txt

    1 directory, 4 files

..

* The directory ``dims-new-repo`` is the templated Cookiecutter.

* The directory ``dims-private`` adds additional files by overlaying them
  into the appropriate places created by the main ``dims-new-repo`` templated
  Cookiecutter. It marks the repo as being non-public with warnings in
  documentation and a file named ``DO_NOT_PUBLISH_THIS_REPO`` in the top level
  directory to remind against publishing. It also includes hooks to ensure
  proper modes on SSH private key files.

* The file ``dims-new-repo.yml`` is a template for variables that can be
  used to over-ride the defaults contained in the Cookiecutter directory.

* The file ``README.txt`` is an example of how to use this Cookiecutter.

Files at this top level are not propagated to the output by ``cookiecutter``,
only the contents of the slug directory tree rooted at
``{{cookiecutter.project_slug}}`` will be included.

.. _dimscookiecutters:

The ``dims-new-repo`` Cookiecutter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Going one level deeper into the Cookiecutter template directory ``dims-new-repo``,
you will find the following files and directories:

.. code-block:: none

    $ tree -a cookiecutter/dims-new-repo/
    cookiecutter/dims-new-repo/
    ├── cookiecutter.json
    ├── {{cookiecutter.project_slug}}
    │   ├── .bumpversion.cfg
    │   ├── docs
    │   │   ├── build
    │   │   │   └── .gitignore
    │   │   ├── Makefile
    │   │   └── source
    │   │       ├── conf.py
    │   │       ├── index.rst
    │   │       ├── introduction.rst
    │   │       ├── license.rst
    │   │       ├── license.txt
    │   │       ├── static
    │   │       │   └── .gitignore
    │   │       ├── templates
    │   │       │   └── .gitignore
    │   │       ├── UW-logo-16x16.ico
    │   │       ├── UW-logo-32x32.ico
    │   │       ├── UW-logo.ico
    │   │       └── UW-logo.png
    │   ├── README.rst
    │   └── VERSION
    └── hooks
        └── post_gen_project.sh

    7 directories, 18 files

..


* The directory ``{{cookiecutter.project_slug}}`` is what is called
  the *slug* directory, a directory that will be processed as a
  template to produce a new directory with specific content based
  on variable expansion. It contains all the other files, pre-configured
  for use by programs like Sphinx, ``bumpversion``, and Git.

  .. note::

     Note the name of this directory includes paired curly braces (``{{`` and ``}}``)
     that tell Jinja to substitute the value of a variable into the template.
     In the Ansible world, some people call these "mustaches" (tilt you head and
     squint a little and you'll get it.)

     The thing inside the mustaches in this directory name is a Jinja
     dictionary variable reference, with ``cookiecutter`` being the top level
     dictionary name and ``project_slug`` being the key to an entry in the
     dictionary. You will see this variable name below in the ``cookiecutter.json``
     default file and ``dims-new-repo.yml`` configuration file.

     The curly brace characters (``{}``) are also Unix shell metacharacters
     used for `advanced filename globbing`_, so you may need to escape them
     using ``''`` or ``\`` on a shell command line "remove the magic." For
     example, if you ``cd`` into the ``dims-new-repo`` directory, type ``ls {``
     and then press ``TAB`` for file name completion, you will see the
     following:

     .. code-block:: bash

        $ ls \{\{cookiecutter.project_slug\}\}/

     ..

  ..

.. _advanced filename globbing: http://tldp.org/LDP/GNU-Linux-Tools-Summary/html/x11655.htm

* The file ``cookiecutter.json`` is the set of defaults in JSON
  format. Templated files in the *slug* directory will be substituted
  from these variables. If desired, ``cookiecutter`` will use these
  to produce prompts that you can fill in with specifics at run time.

* The directory ``hooks`` is holds scripts that are used for pre-
  and post-processing of the template output directory. (You may not
  need to pay any attention to this directory.)


Project Slug Directory
""""""""""""""""""""""

Path: ``$GIT/ansible-dims-playbooks/files/cookiecutter/dims-new-repo/{{ cookiecutter.project_slug }}``

Every Cookiecutter includes a directory with a name in the format of
``{{cookiecutter.project_slug}}``. This is how the ``cookiecutter`` program
knows where to start templating. Everything outside of this directory is
ignored in the creation of the new project. The directory hierarchy of this
directory will be used to make the directory hierarchy of the new project. The
user can populate the ``{{cookiecutter.project_slug}}`` directory with any
subdirectory structure and any files they will need to instantiate templated
versions of their project. Any files in this directory can similarly use
variables of the same format as the slug directory.  These variables must be
defined by either defaults or a configuration file or an undefined variable
error will occur.

Look back at the example ``cookiecutter.json`` file. For that Cookiecutter,
a new repo with the project name ``DIMS Test Repo`` would be found in a
directory called  ``dims-test-repo`` (this is the ``{{cookiecutter.project_name}}``
to ``{{cookiecutter.project_slug}}`` conversion).

Look back at the ``tree -a`` output. For that cookiecutter, a new
directory would have a ``docs/`` subdirectory, with its own subdirectories
and files, a ``.bumpversion.cfg`` file, and a
``VERSION`` file. Any time this cookiecutter is used, this is the hierarchy
and files the new repo directory will have.

.. code-block:: none

     {{cookiecutter.project_slug}}/
     ├── .bumpversion.cfg
     ├── docs
     │   ├── Makefile
     │   └── source
     │       ├── conf.py
     │       ├── index.rst
     │       ├── license.rst
     │       ├── license.txt
     │       ├── UW-logo-16x16.ico
     │       ├── UW-logo-32x32.ico
     │       ├── UW-logo.ico
     │       └── UW-logo.png
     └── VERSION

     4 directories, 10 files

..

  * ``.bumpversion.cfg``: used to keep track of the version in various
    locations in the repo.
  * ``VERSION``: file containing current version number
  * ``docs/``:

    * ``Makefile``: used to build HTML and LaTeX documents
    * ``source/``:

      - minimal doc set (``index.rst`` and ``license.rst``)
      - ``.ico`` and ``.png`` files for branding the documents
      - ``conf.py`` which configures the document theme,
        section authors, project information, etc. Lots of variables
        used in this file, set from ``cookiecutter.json`` values.


Template Defaults
"""""""""""""""""

Path: ``$GIT/ansible-dims-playbooks/files/cookiecutter/dims-new-repo/cookiecutter.json``

Every cookiecutter has a ``cookiecutter.json`` file. This file contains
the default variable definitions for a template. When the user runs
the ``cookiecutter`` command, they can be prompted for this information.
If the user provides no information, the defaults already contained in
the ``.json`` file will be used to create the project.

The ``cookiecutter.json`` file in the ``dims-new-repo`` Cookiecutter slug
directory contains the following:

.. literalinclude:: ../../files/cookiecutter/dims-new-repo/cookiecutter.json
   :language: json

Python commands can be used to manipulate the values of one field to
create the value of another field.

For example, you can generate the project slug from the repository
name using the following:

.. code-block:: json

    {

    "project_name": "DIMS New Repo Boilerplate",
    "project_slug": "{{ cookiecutter.project_name.lower().replace(' ', '-') }}",

    }

..

The resulting slug would look like ``dims-new-repo-boilerplate``.

You can also load Jinja extensions by including an array named ``_extensions``
(shown array at the bottom of the JSON defaults file.) The variables
``release_date`` and ``project_copyright_date`` are produced programmatically
using the ``Jinja2_time.TimeExtension`` extension.  These are filled with the
current date/time as defined. You can over-ride them using the
``dims-new-repo.yml`` YAML file adding the variables by name.

Custom Configuration File
"""""""""""""""""""""""""

Path: ``$GIT/ansible-dims-playbooks/files/cookiecutter/dims-new-repo/dims-new-repo.yml``

The file ``dims-new-repo.yml`` is a configuration file that can
be passed to ``cookiecutter`` using the ``--config-file`` command
line option.  It sets the dictionary ``default_context`` for
``cookiecutter`` at runtime, over-riding the defaults from
the ``cookiecutter.json`` file.

.. literalinclude:: ../../files/cookiecutter/dims-new-repo.yml
   :language: yaml

To use this file, copy the file ``dims-new-repo.yml`` and
give it a unique name to differentiate it from other configuration
files. This allows you to easily create more than one repository
directory at a time, as well as save the settings to easily repeat
the process for development and testing of the slug directory
when you need to update it.  For this
example, we will use ``testrepo.yml`` for the configuration file.

.. code-block:: none

    $ cp dims-new-repo.yml testrepo.yml
    $ vi testrepo.yml

..

Edit the template to customize is at necessary. It should end
up looking something like this:

.. code-block:: yaml

    $ cat testrepo.yml
    ---

    default_context:
      full_name: "Dave Dittrich"
      email: "dittrich@u.washington.edu"
      project_name: "DIMS Ansible Playbooks"
      project_slug: "ansible-dims-playbooks"
      project_short_description: "Ansible Playbooks for DIMS System Configuration"
      project_copyright_name: "University of Washington"

..


.. dims-new-repo/cookiecutter.json
.. """"""""""""""""""""""""""""""""""
..
.. .. include:: ../../files/cookiecutter/dims-new-repo/cookiecutter.json
..    :literal:
..
.. These are the basic elements required for instantiating a new repo
.. with cookiecutter. The values are used to fill in variables in the
.. template version of ``conf.py``, ``index.rst``, and any other files
.. that are templated.
..
.. There are two ways to create the new directories using
.. ``cookiecutter``: *interactive* and *non-interactive*.
..
.. * The first is interactive, using the values for the keys defined
..   in ``cookiecutter.json`` as defaults. ``cookiecutter`` then prompts
..   for specific values to use for processing the templates. This is
..   a simple way to create one new repo.
..
.. * The second is non-interactive, using a YAML file that contains the
..   specifics to override some or all of the defaults without having to
..   respond to prompts.
..
..
..   *USER INPUT REQUIRED*
..
..   * ``full_name``: used to set variables that need an author name.
..   * ``email``: used to set variables that need an author email.
..   * ``project_name``: the repo's official name. DIMS has been,
..     generally, naming repos
..     "DIMS $service_or_function". Used in various source/ files.
..   * ``project_short_description``: whatever the user gives here is used
..     in various source/ files.
..   * ``release_date``:  date in which documentation is first published.
..
..
..   *USER INPUT NOT REQUIRED*
..
..   * ``project_version``: If the user wants a
..     different start version number, their input is required. Otherwise,
..     the user doesn't need to provide anything (they can just hit
..     "Enter" at that prompt).
..   * ``project_slug``: takes the ``project_name`` field and turns it
..     into a repo name. DIMS has been, generally, using all lowercase
..     and "-" to separate words when naming a repo. User input is not
..     required.
..   * ``project_copyright_name``
..     This is used to create copyright description in the index's
..     "License" section. User input is not required unless the user wants
..     a different copyright name.
..   * ``project_copyright_date``: When we roll
..     to the new year, this default will have to be updated. User input
..     is not required.
..
..   Once the prompt finishes, the new repo directory is created, and the
..   files are configured with the information in cookiecutter.json.
..

Usage
"""""

By default, ``cookiecutter`` will generate the new directory with the
name specified by the ``cookiecutter.project_slug`` variable in
the current working directory. Provide a relative or absolute path
to another directory (e.g., ``$GIT``, so place the new directory in
the standard DIMS repo directory) using the ``-o`` command line option.
In this example, we will let ``cookiecutter`` prompt for alternatives
to the defaults from the ``cookiecutter.json`` file:

.. code-block:: none
   :emphasize-lines: 3-11

   $ cd $GIT/dims-ci-utils/cookiecutter
   $ cookiecutter -o ~/ dims-new-repo/
   full_name [DIMS User]: Megan Boggess
   email []: mboggess@uw.edu
   project_name [DIMS New Repo Boilerplate]: Test Repo
   project_short_description [DIMS New Repo Boilerplate contains docs/ setup, conf.py template, .bumpversion.cfg, LICENSE file, and other resources needed for instantiating a new repo.]: This is just a test
   release_date [20YY-MM-DD]: 2015-10-29
   project_version [1.0.0]:
   project_slug [test-repo]:
   project_copyright_name [University of Washington]:
   project_copyright_date [2014-2015]:
   $ cd ~/test-repo
   $ ls
   docs  VERSION
   $ tree -a
   .
   ├── .bumpversion.cfg
   ├── docs
   │   ├── build
   │   │   └── .gitignore
   │   ├── Makefile
   │   └── source
   │       ├── conf.py
   │       ├── images
   │       ├── index.rst
   │       ├── license.rst
   │       ├── license.txt
   │       ├── static
   │       │   └── .gitignore
   │       ├── templates
   │       │   └── .gitignore
   │       ├── UW-logo-16x16.ico
   │       ├── UW-logo-32x32.ico
   │       ├── UW-logo.ico
   │       └── UW-logo.png
   └── VERSION

   3 directories, 14 files

..

The highlighted section in the above code block is the prompts for
cookiecutter.json configuring. As you can see, I answer the first five prompts,
the ones which require user input, and leave the rest blank because they don't
require user input.

Following that, you can see the ``tree`` structure of the newly created repo
called "test-repo". Once this is done, you can finish following repo setup
instructions found in :ref:`dimsdevguide:sourcemanagement`.

Alternatively, you can change your current working directory to be the location
where you want the templated directory to be created and specify the template
source using an absolute path.  In this example, we also use a configuration file,
also specified with an absolute path:

.. code-block:: none

    $ mkdir -p /tmp/new/repo/location
    $ cd /tmp/new/repo/location
    $ cookiecutter --no-input \
    > --config-file /home/dittrich/dims/git/dims-ci-utils/cookiecutter/testrepo.yml \
    > /home/dittrich/dims/git/dims-ci-utils/cookiecutter/dims-new-repo
    [+] Fix underlining in these files:
    /tmp/new/repo/location/ansible-dims-playbooks/docs/source/index.rst
    /tmp/new/repo/location/ansible-dims-playbooks/README.rst
    $ tree
    .
    └── ansible-dims-playbooks
        ├── docs
        │   ├── build
        │   ├── Makefile
        │   └── source
        │       ├── conf.py
        │       ├── index.rst
        │       ├── introduction.rst
        │       ├── license.rst
        │       ├── license.txt
        │       ├── _static
        │       ├── _templates
        │       ├── UW-logo-16x16.ico
        │       ├── UW-logo-32x32.ico
        │       ├── UW-logo.ico
        │       └── UW-logo.png
        ├── README.rst
        └── VERSION

    6 directories, 12 files

..

Note the lines that show up right after the command line
(highlighted here):

.. code-block:: none

    $ cookiecutter --no-input -f -o /tmp --config-file testrepo.yml dims-new-repo
    [+] Fix underlining in these files:
    /tmp/ansible-dims-playbooks/docs/source/index.rst
    /tmp/ansible-dims-playbooks/README.rst

..

ReStructureText (RST) files *must* have section underlines that are
exactly the same length as the text for the section. Since the templated
output length is not known when the template is written, it is impossible
to correctly guess 100% of the time how many underline characters are
needed. This could be handled with post-processing using ``awk``, ``perl``,
etc., or it can just be called out by identifying a fixed string. The latter
is what this Cookiecutter uses.

To produce one of these warning messages, simply place a line containing
the string ``FIX_UNDERLINE`` in the template file, as shown here:

.. literalinclude:: ../../files/cookiecutter/dims-new-repo/{{cookiecutter.project_slug}}/docs/source/index.rst
   :language: rst
   :emphasize-lines: 6,7

Edit these files to fix the underline before committing them to Git, as
shown here:

.. code-block:: rst

    DIMS Ansible Playbooks v |release|
    ==================================

..

.. _dims_private:

The ``dims-private`` Cookiecutter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If the repo is supposed to be non-public, use the same configuration file
to overlay files from the ``dims-private`` Cookiecutter onto the same output
directory as the main repo directory. It uses a symbolic link for the
``cookiecutter.json`` file to have exactly the same defaults and using the
same configuration file ensures the same output directory and templated
values are output as appropriate.

.. code-block:: none

    $ cookiecutter --no-input -f -o /tmp --config-file testrepo.yml dims-private
    [+] Fix underlining in these files:
    /tmp/ansible-dims-playbooks/docs/source/index.rst
    /tmp/ansible-dims-playbooks/README.rst

..

The ``dims-private`` Cookiecutter also adds a directory ``hooks/`` and a ``Makefile``
that installs ``post-checkout`` and ``post-merge`` hooks that Git will run
after checking out and merging branches to fix file permissions on SSH private
keys. Git has a limitation in its ability to track all Unix mode bits. It only
tracks whether the execute bit is set or not. This causes the wrong mode bits for
SSH keys that will prevent them from being used. These hooks fix this in a very
simplistic way (though it does work.)

The very first time after the repository is cloned, the hooks will not be
installed as they reside in the ``.git`` directory. Install them by typing
``make`` at the top level of the repository:

.. code-block:: none

    $ make
    [+] Installing .git/hooks/post-checkout
    [+] Installing .git/hooks/post-merge

..

The hooks will be triggered when needed and you will see an added line
in the Git output:

.. code-block:: none

    $ git checkout master
    Switched to branch 'master'
    [+] Verifying private key permissions and correcting if necessary

..

.. _popular Cookiecutter template: https://cookiecutter.readthedocs.org/en/latest/readme.html
.. _Latest Cookiecutter Docs: https://cookiecutter.readthedocs.org/en/latest/
.. _Python Package Project Template Example: https://github.com/audreyr/cookiecutter
.. _Cookiecutter Tutorial: http://www.pydanny.com/cookie-project-templates-made-easy.html

.. _populatingprivate:

Populating the Private Configuration Repository
-----------------------------------------------

Start creating your local customization repository using the ``cookiecutter``
template discussed in the previous section. We will call this private
deployment ``devtest``, thus creating a repository in a the directory named
``$GIT/private-devtest``. Here is the configuration file we will use:

.. code-block:: none

    $ cd $GIT
    $ cat private-devtest.yml
    ---

    default_context:
      full_name: "Dave Dittrich"
      email: "dittrich@u.washington.edu"
      project_name: "Deployment \"devtest\" private configuration"
      project_slug: "private-devtest"
      project_short_description: "Ansible playbooks private content for \"devtest\" deployment"
      project_copyright_name: "University of Washington"

..

First, generate the new repository from the ``dims-new-repo`` template, followed by adding
in the files from the ``dims-private`` template.

.. code-block:: none

    $ cookiecutter --no-input -f -o . --config-file private-devtest.yml $GIT/dims-ci-utils/cookiecutter/dims-new-repo
    [+] Fix underlining in these files:
    ./private-devtest/docs/source/index.rst
    ./private-devtest/README.rst
    $ cookiecutter --no-input -f -o . --config-file private-devtest.yml $GIT/dims-ci-utils/cookiecutter/dims-private

..

.. note::

   Be sure to edit the two documents that are mentioned above right now to fix the
   headings, and possibly to change the documentation in the ``README.rst`` file
   to reference the actual location of the private GIT repository.

..

You now have a directory ready to be turned into a Git repository with
all of the requisite files for ``bumpversion`` version number tracking,
Sphinx documentation, and hooks for ensuring proper permissions on SSH
private key files.

.. code-block:: none

        $ tree -a private-devtest
        private-devtest
        ├── .bumpversion.cfg
        ├── docs
        │   ├── .gitignore
        │   ├── Makefile
        │   └── source
        │       ├── conf.py
        │       ├── index.rst
        │       ├── introduction.rst
        │       ├── license.rst
        │       ├── license.txt
        │       ├── _static
        │       │   └── .gitignore
        │       ├── _templates
        │       │   └── .gitignore
        │       ├── UW-logo-16x16.ico
        │       ├── UW-logo-32x32.ico
        │       ├── UW-logo.ico
        │       └── UW-logo.png
        ├── DO_NOT_PUBLISH_THIS_REPO
        ├── hooks
        │   ├── post-checkout
        │   └── post-merge
        ├── Makefile
        ├── README.rst
        └── VERSION

        5 directories, 20 files

    ..

Next, begin by creating the Ansible ``inventory/`` directory
that will describe your deployment. Copy the ``group_vars``,
``host_vars``, and ``inventory`` directory trees to the new
custom directory.

.. code-block:: none

    $ cp -vrp $PBR/{group_vars,host_vars,inventory} -t private-devtest
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars’ -> ‘private-devtest/group_vars’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all’ -> ‘private-devtest/group_vars/all’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/consul.yml’ -> ‘private-devtest/group_vars/all/consul.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/rsyslog.yml’ -> ‘private-devtest/group_vars/all/rsyslog.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/prisem_rpc.yml’ -> ‘private-devtest/group_vars/all/prisem_rpc.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/trident.yml’ -> ‘private-devtest/group_vars/all/trident.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/postgresql.yml’ -> ‘private-devtest/group_vars/all/postgresql.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/nginx.yml’ -> ‘private-devtest/group_vars/all/nginx.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/.dims.yml.swp’ -> ‘private-devtest/group_vars/all/.dims.yml.swp’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/networks.yml’ -> ‘private-devtest/group_vars/all/networks.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/docker.yml’ -> ‘private-devtest/group_vars/all/docker.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/dnsmasq.yml’ -> ‘private-devtest/group_vars/all/dnsmasq.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/dims.yml’ -> ‘private-devtest/group_vars/all/dims.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/swarm.yml’ -> ‘private-devtest/group_vars/all/swarm.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/squid-deb-proxy.yml’ -> ‘private-devtest/group_vars/all/squid-deb-proxy.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/vagrant.yml’ -> ‘private-devtest/group_vars/all/vagrant.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/all/go.yml’ -> ‘private-devtest/group_vars/all/go.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/vault.yml’ -> ‘private-devtest/group_vars/vault.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/group_vars/README.txt’ -> ‘private-devtest/group_vars/README.txt’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars’ -> ‘private-devtest/host_vars’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/purple.devops.local.yml’ -> ‘private-devtest/host_vars/purple.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/.gitignore’ -> ‘private-devtest/host_vars/.gitignore’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/node02.devops.local.yml’ -> ‘private-devtest/host_vars/node02.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/yellow.devops.local.yml’ -> ‘private-devtest/host_vars/yellow.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/green.devops.local.yml’ -> ‘private-devtest/host_vars/green.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/red.devops.local.yml’ -> ‘private-devtest/host_vars/red.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/orange.devops.local.yml’ -> ‘private-devtest/host_vars/orange.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/vmhost.devops.local.yml’ -> ‘private-devtest/host_vars/vmhost.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/node03.devops.local.yml’ -> ‘private-devtest/host_vars/node03.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/node01.devops.local.yml’ -> ‘private-devtest/host_vars/node01.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/blue14.devops.local.yml’ -> ‘private-devtest/host_vars/blue14.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/blue16.devops.local.yml’ -> ‘private-devtest/host_vars/blue16.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/host_vars/hub.devops.local.yml’ -> ‘private-devtest/host_vars/hub.devops.local.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory’ -> ‘private-devtest/inventory’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/dns_zones’ -> ‘private-devtest/inventory/dns_zones’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/dns_zones/nodes.yml’ -> ‘private-devtest/inventory/dns_zones/nodes.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/trident’ -> ‘private-devtest/inventory/trident’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/trident/nodes.yml’ -> ‘private-devtest/inventory/trident/nodes.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/vagrants’ -> ‘private-devtest/inventory/vagrants’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/vagrants/nodes.yml’ -> ‘private-devtest/inventory/vagrants/nodes.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/ci-server’ -> ‘private-devtest/inventory/ci-server’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/ci-server/nodes.yml’ -> ‘private-devtest/inventory/ci-server/nodes.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/swarm’ -> ‘private-devtest/inventory/swarm’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/swarm/nodes.yml’ -> ‘private-devtest/inventory/swarm/nodes.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/private’ -> ‘private-devtest/inventory/private’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/private/nodes.yml’ -> ‘private-devtest/inventory/private/nodes.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/host_vars’ -> ‘private-devtest/inventory/host_vars’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/group_vars’ -> ‘private-devtest/inventory/group_vars’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/all.yml’ -> ‘private-devtest/inventory/all.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/nameserver’ -> ‘private-devtest/inventory/nameserver’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/nameserver/nodes.yml’ -> ‘private-devtest/inventory/nameserver/nodes.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/ansible-server’ -> ‘private-devtest/inventory/ansible-server’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/ansible-server/nodes.yml’ -> ‘private-devtest/inventory/ansible-server/nodes.yml’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/coreos’ -> ‘private-devtest/inventory/coreos’
    ‘/home/dittrich/dims/git/ansible-dims-playbooks/inventory/coreos/nodes.yml’ -> ‘private-devtest/inventory/coreos/nodes.yml’

..

The names of hosts in the inventory need to be changed to match the new
deployment name. This is necessary for mapping inventory host names to
``host_vars`` files, as well as to generate the proper split-DNS name to IP
address mappings (among other things). In the inventory, this process can
be automated a little bit.

Start by verifying that the word ``local`` only occurs in the inventory
in places where it can be cleanly edited using a simple inline string
editing (``sed`` style) regular expression.

.. code-block:: none

    $ grep -r local inventory
    inventory/dns_zones/nodes.yml:      'local':
    inventory/dns_zones/nodes.yml:          - 'red.devops.local'
    inventory/dns_zones/nodes.yml:          - 'vmhost.devops.local'
    inventory/dns_zones/nodes.yml:        mxserver: 'vmhost.devops.local'
    inventory/dns_zones/nodes.yml:    local:
    inventory/dns_zones/nodes.yml:        'vmhost.devops.local':
    inventory/dns_zones/nodes.yml:        'red.devops.local':
    inventory/dns_zones/nodes.yml:        'orange.devops.local':
    inventory/dns_zones/nodes.yml:        'blue14.devops.local':
    inventory/dns_zones/nodes.yml:        'blue16.devops.local':
    inventory/dns_zones/nodes.yml:        'yellow.devops.local':
    inventory/dns_zones/nodes.yml:        'purple.devops.local':
    inventory/dns_zones/nodes.yml:        'hub.devops.local':
    inventory/dns_zones/nodes.yml:        'node01.devops.local':
    inventory/dns_zones/nodes.yml:        'node02.devops.local':
    inventory/dns_zones/nodes.yml:        'node03.devops.local':
    inventory/dns_zones/nodes.yml:        'node01.devops.local':
    inventory/dns_zones/nodes.yml:        'node02.devops.local':
    inventory/dns_zones/nodes.yml:        'node03.devops.local':
    inventory/trident/nodes.yml:    'yellow.devops.local':
    inventory/trident/nodes.yml:    'purple.devops.local':
    inventory/vagrants/nodes.yml:      'local': 'eth1'
    inventory/vagrants/nodes.yml:    'red.devops.local':
    inventory/vagrants/nodes.yml:    'node01.devops.local':
    inventory/vagrants/nodes.yml:    'node02.devops.local':
    inventory/vagrants/nodes.yml:    'node03.devops.local':
    inventory/vagrants/nodes.yml:    'yellow.devops.local':
    inventory/vagrants/nodes.yml:    'purple.devops.local':
    inventory/vagrants/nodes.yml:    'blue14.devops.local':
    inventory/vagrants/nodes.yml:    'orange.devops.local':
    inventory/vagrants/nodes.yml:        'red.devops.local':
    inventory/vagrants/nodes.yml:        'node01.devops.local':
    inventory/vagrants/nodes.yml:        'node02.devops.local':
    inventory/vagrants/nodes.yml:        'node03.devops.local':
    inventory/vagrants/nodes.yml:        'yellow.devops.local':
    inventory/vagrants/nodes.yml:        'orange.devops.local':
    inventory/vagrants/nodes.yml:        'purple.devops.local':
    inventory/vagrants/nodes.yml:        'blue14.devops.local':
    inventory/vagrants/nodes.yml:        'red.devops.local':
    inventory/vagrants/nodes.yml:        'yellow.devops.local':
    inventory/vagrants/nodes.yml:        'orange.devops.local':
    inventory/ci-server/nodes.yml:#     jenkins_hostname: jenkins.devops.local
    inventory/ci-server/nodes.yml:    jenkins_hostname: localhost
    inventory/ci-server/nodes.yml:    'orange.devops.local':
    inventory/swarm/nodes.yml:    'red.devops.local':
    inventory/swarm/nodes.yml:    'yellow.devops.local':
    inventory/swarm/nodes.yml:    'purple.devops.local':
    inventory/swarm/nodes.yml:    'node01.devops.local':
    inventory/swarm/nodes.yml:    'node02.devops.local':
    inventory/swarm/nodes.yml:    'node03.devops.local':
    inventory/swarm/nodes.yml:        'node01.devops.local':
    inventory/swarm/nodes.yml:        'node02.devops.local':
    inventory/swarm/nodes.yml:        'node03.devops.local':
    inventory/swarm/nodes.yml:        'red.devops.local':
    inventory/swarm/nodes.yml:        'yellow.devops.local':
    inventory/swarm/nodes.yml:        'purple.devops.local':
    inventory/private/nodes.yml:    'vmhost.devops.local':
    inventory/private/nodes.yml:    'red.devops.local':
    inventory/private/nodes.yml:    'orange.devops.local':
    inventory/private/nodes.yml:    'blue14.devops.local':
    inventory/private/nodes.yml:    'blue16.devops.local':
    inventory/private/nodes.yml:    'yellow.devops.local':
    inventory/private/nodes.yml:    'purple.devops.local':
    inventory/private/nodes.yml:    'hub.devops.local':
    inventory/private/nodes.yml:    'node01.devops.local':
    inventory/private/nodes.yml:    'node02.devops.local':
    inventory/private/nodes.yml:    'node03.devops.local':
    inventory/all.yml:    deployment: 'local'
    inventory/all.yml:    dims_domain: 'devops.local'
    inventory/all.yml:    'vmhost.devops.local':
    inventory/all.yml:    'orange.devops.local':
    inventory/all.yml:    'red.devops.local':
    inventory/all.yml:    'node01.devops.local':
    inventory/all.yml:    'node02.devops.local':
    inventory/all.yml:    'node03.devops.local':
    inventory/all.yml:    'yellow.devops.local':
    inventory/all.yml:    'purple.devops.local':
    inventory/all.yml:    'blue14.devops.local':
    inventory/nameserver/nodes.yml:    'red.devops.local':
    inventory/nameserver/nodes.yml:    'vmhost.devops.local':
    inventory/ansible-server/nodes.yml:    'vmhost.devops.local':
    inventory/ansible-server/nodes.yml:    'orange.devops.local':
    inventory/coreos/nodes.yml:    iptables_rules: rules.v4.coreos-local.j2
    inventory/coreos/nodes.yml:    dims_environment: environment.coreos-local.j2
    inventory/coreos/nodes.yml:    # This is not specific to "local" deployment, but is specific to coreos
    inventory/coreos/nodes.yml:    'node01.devops.local':
    inventory/coreos/nodes.yml:    'node02.devops.local':
    inventory/coreos/nodes.yml:    'node03.devops.local':

..

Doing this on a BASH command line in Linux would highlight the
word ``local``, making it easier to see, but there is no need
to do anything other than simply substitute ``local`` with
``devtest``.

.. caution::

    The kind of bulk editing that will be shown next is powerful, which means
    it is also risky.  Accidental damage from typos on the command line can be
    very difficult to recover from. For example, if you were to blindly change
    the word ``local`` to ``devtest`` in the following files, you would break
    many things:

    .. code-block:: none

        . . .
        ../roles/postgresql/templates/postgresql/postgresql.conf.j2:listen_addresses = 'localhost'              # what IP address(es) to listen on;
        ../roles/postgresql/templates/postgresql/postgresql.conf.j2:log_timezone = 'localtime'
        ../roles/postgresql/templates/postgresql/postgresql.conf.j2:timezone = 'localtime'
        . . .
        ../roles/postgresql/templates/postgresql/pg_hba.conf.j2:local   all             all                                     trust
        ../roles/postgresql/templates/postgresql/pg_hba.conf.j2:local   replication     postgres                                trust
          . . .
        ../roles/nginx/templates/nginx/nginx.conf.j2:   access_log syslog:server=localhost,facility={{ syslog_facility }},tag=nginx,severity={{ syslog_severity }};
        ../roles/nginx/templates/nginx/nginx.conf.j2:   error_log syslog:server=localhost,facility={{ syslog_facility }},tag=nginx,severity={{ syslog_severity }};
        . . .
        ../roles/base/files/hub.bash_completion.sh:    local line h k v host=${1:-github.com} config=${HUB_CONFIG:-~/.config/hub}
        ../roles/base/files/hub.bash_completion.sh:    local f format=$1
        ../roles/base/files/hub.bash_completion.sh:    local i remote repo branch dir=$(__gitdir)
        ../roles/base/files/hub.bash_completion.sh:    local i remote=${1:-origin} dir=$(__gitdir)
        . . .
        ../roles/base/files/git-prompt.sh:      local upstream=git legacy="" verbose="" name=""
        ../roles/base/files/git-prompt.sh:      local output="$(git config -z --get-regexp '^(svn-remote\..*\.url|bash\.showupstream)$' 2>/dev/null | tr '\0\n' '\n ')"
        ../roles/base/files/git-prompt.sh:              local -a svn_upstream
        ../roles/base/files/git-prompt.sh:                      local n_stop="${#svn_remote[@]}"
        ../roles/base/files/git-prompt.sh:              local commits
        . . .
        ../roles/base/files/dims_functions.sh:    local retval=$1 && shift
        ../roles/base/files/dims_functions.sh:    local script=$1
        ../roles/base/files/dims_functions.sh:    local n=${#on_exit_items[*]}
        ../roles/base/files/dims_functions.sh:    local _deployment=${1:-${DEPLOYMENT}}
        . . .

    ..

    If you are not comfortable and confident that you know what you are doing,
    practice first by making a copy of the directory tree to the ``/tmp``
    directory and trying the edits there. Using ``diff -r`` against both the
    original directory and the temporary directory will show you the effects
    and allow you to validate they reflect what you desire before applying to
    the actual files.

..

Use the ``-l`` option of ``grep`` to get just
the file names, save them to a file, and use that file in
an inline command substitution in a ``for`` loop to edit
the files inline using ``perl``.

.. code-block:: none

    $ grep -lr local inventory > /tmp/files
    $ for F in $(cat /tmp/files); do perl -pi -e 's/local/devtest/' $F; done

..

Next, rename all of the ``host_vars`` files to have names that match
the deployment name ``devtest`` and the changes made to the inventory
files, and carefully change the internal contents like the last
step so they match as well.

.. code-block:: none

    $ cd private-devtest/host_vars/
    $ ls
    blue14.devops.local.yml  green.devops.local.yml  node01.devops.local.yml
    node03.devops.local.yml  purple.devops.local.yml vmhost.devops.local.yml
    blue16.devops.local.yml  hub.devops.local.yml    node02.devops.local.yml
    orange.devops.local.yml  red.devops.local.yml    yellow.devops.local.yml
    $ for F in *.yml; do mv $F $(echo $F | sed 's/local/devtest/'); done
    $ ls
    blue14.devops.devtest.yml  green.devops.devtest.yml  node01.devops.devtest.yml
    node03.devops.devtest.yml  purple.devops.devtest.yml vmhost.devops.devtest.yml
    blue16.devops.devtest.yml  hub.devops.devtest.yml    node02.devops.devtest.yml
    orange.devops.devtest.yml  red.devops.devtest.yml    yellow.devops.devtest.yml
    $ grep local *
    blue14.devops.devtest.yml:# File: host_vars/blue14.devops.local.yml
    blue16.devops.devtest.yml:# File: host_vars/blue16.devops.local.yml
    green.devops.devtest.yml:# File: host_vars/green.devops.local.yml
    hub.devops.devtest.yml:# File: host_vars/hub.devops.local.yml
    node01.devops.devtest.yml:# File: host_vars/node01.devops.local.yml
    node02.devops.devtest.yml:# File: host_vars/node02.devops.local.yml
    node03.devops.devtest.yml:# File: host_vars/node03.devops.local.yml
    orange.devops.devtest.yml:# file: host_vars/orange.devops.local
    orange.devops.devtest.yml:jenkins_url_external: 'http://orange.devops.local:8080'
    purple.devops.devtest.yml:# File: host_vars/purple.devops.local.yml
    red.devops.devtest.yml:# File: host_vars/red.devops.local.yml
    vmhost.devops.devtest.yml:  'local': 'vboxnet3'
    yellow.devops.devtest.yml:# File: host_vars/yellow.devops.local.yml
    $ grep -l local *.yml > /tmp/files
    $ for F in $(cat /tmp/files); do perl -pi -e 's/local/devtest/' $F; done
    $ cd -
    /home/dittrich/dims/git

..
