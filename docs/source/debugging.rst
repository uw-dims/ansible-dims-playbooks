.. _debugging:

Debugging with Ansible and Vagrant
==================================

This chapter covers some tactics and procedures used for testing and debugging
Ansible inventories, playbooks, roles, etc. using Vagrants with ``bats`` tests
as the test and validation mechanisms.

More general debugging strategies and techniques are covered in Section
:ref:`dimsdevguide:debugging` of the :ref:`dimsdevguide:dimsdevguide`.

.. _debuggingansible:

Debugging Ansible
----------------

Ansible has two primary methods with which it is invoked -- ``ansible-playbook``
to run playbooks, and ``ansible`` (a.k.a., "ad-hoc mode") to run individual
modules one at a time.

* Debugging using the ``debug`` module in "ad-hoc" mode can be used to explore
  the value of variables after processing of the inventory (i.e., group
  definitions, group variables, host variables, etc.) This does not require
  any remote connections, or even an internet connection at all, since the
  ``debug`` module is processed locally on the Ansible control host. (The
  flip side of this is that no Ansible "facts" are available, `because` of
  the fact that no remote connections are made.)

* Debugging playbook execution with ``ansible-playbook`` involves controlling
  the level of verbosity in output of program execution and/or exposing the
  runtime state of variables (possibly obtaining that state remotely from
  running systems) using the ``debug`` module. There is also "single-stepping"
  of playbooks that can be used in conjunction with these mechanisms.


Examining Variables
^^^^^^^^^^^^^^^^^^^

To see the value of the variable ``inventory_hostname`` for a group of hosts
named ``manager``, use the ``debug`` module, the specific inventory to
look at, and pass the group name:

.. code-block:: none

    $ ansible -m debug -a "var=inventory_hostname" manager
    node03.devops.local | SUCCESS => {
        "inventory_hostname": "node03.devops.local"
    }
    node01.devops.local | SUCCESS => {
        "inventory_hostname": "node01.devops.local"
    }
    node02.devops.local | SUCCESS => {
        "inventory_hostname": "node02.devops.local"
    }

..

Ansible variables are sometimes not as straightforward as that. Often
variables are composed from other variables using Jinja templating
expressions in strings which are recursively processed at run time
during template rendering.  This means that you must either be
really good at resolving the nested variable references in your head, or
get used to using Ansible's ``debug`` module with ``msg`` to do the
templating for you. What is more, Ansible variables are all effectively
in a deeply-nested Python dictionary structure that takes some getting
used to. Using data structures properly helps iterate over lists
or dictionary keys using clean algorithms involving `Loops`_.

.. _Loops: http://docs.ansible.com/ansible/latest/playbooks_loops.html

To see how this works, take a look at the following example of the bundle
of Trident packages that are part of a Trident deployment. We want to
validate each package using a common cryptographic hash, so a simple
dictionary keyed on ``url`` and ``sha256sum`` will work.

.. code-block:: yaml

    # Trident components are all loaded at once as a bundle
    trident_dist_bundle:
      - { 'url': '{{ trident_server_disturl }}', 'sha256sum': '{{ trident_server_sha256sum }}' }
      - { 'url': '{{ trident_cli_disturl }}', 'sha256sum': '{{ trident_cli_sha256sum }}' }
      - { 'url': '{{ trident_all_disturl }}', 'sha256sum': '{{ trident_all_sha256sum }}' }
      - { 'url': '{{ pitchfork_disturl }}', 'sha256sum': '{{ pitchfork_sha256sum }}' }
      - { 'url': '{{ trident_wikiexport_disturl }}', 'sha256sum': '{{ trident_wikiexport_sha256sum }}' }

    trident_cli_version: '{{ trident_version }}'
    trident_cli_archive: 'trident-cli_{{ trident_cli_version }}_amd64.deb'
    trident_cli_disturl: '{{ trident_download_dir }}/{{ trident_cli_archive }}'
    trident_cli_sha256sum: '15f11c986493a67e85aa9cffe6719a15a8c6a65b739a2b0adf62ce61e53f4203'
    trident_cli_opts: ''

    trident_server_version: '{{ trident_version }}'
    trident_server_archive: 'trident-server_{{ trident_server_version }}_amd64.deb'
    trident_server_disturl: '{{ trident_download_dir }}/{{ trident_server_archive }}'
    trident_server_sha256sum: 'a8af27833ada651c9d15dc29d04451250a335ae89a0d2b66bf97a787dced9956'
    trident_server_opts: '--syslog'

    trident_all_version: '{{ trident_version }}'
    trident_all_archive: 'trident_{{ trident_all_version }}_all.deb'
    trident_all_disturl: '{{ trident_download_dir }}/{{ trident_all_archive }}'
    trident_all_sha256sum: '67f57337861098c4e9c9407592c46b04bbc2d64d85f69e8c0b9c18e8d5352ea6' #trident_1.4.5_all.deb

    trident_wikiexport_version: '{{ trident_version }}'
    trident_wikiexport_archive: 'trident-wikiexport_{{ trident_wikiexport_version }}_amd64.deb'
    trident_wikiexport_disturl: '{{ trident_download_dir }}/{{ trident_wikiexport_archive }}'
    trident_wikiexport_sha256sum: '4d2f9d62989594dc5e839546da596094c16c34d129b86e4e323556f1ca1d8805'

    # Pitchfork tracks its own version
    pitchfork_version: '1.9.4'
    pitchfork_archive: 'pitchfork-data_{{ pitchfork_version }}_all.deb'
    pitchfork_disturl: '{{ trident_download_dir }}/{{ pitchfork_archive }}'
    pitchfork_sha256sum: '5b06ae4a20a16a7a5e59981255ba83818f67224b68f6aaec014acf51ca9d1a44'

    # Trident perl tracks its own version
    # TODO(dittrich): trident-perl is private artifact - using our cached copy
    trident_perl_version: '0.1.0'
    trident_perl_archive: 'trident-perl_{{ trident_perl_version }}_amd64.deb'
    trident_perl_disturl: '{{ artifacts_url }}/{{ trident_perl_archive }}'
    trident_perl_sha256sum: '2f120dc75f75f8b2c8e5cdf55a29984e24ee749a75687a10068ed8f353098ffb'

..

To see what the ``trident_dist_bundle`` looks like to better visualize how to
loop on it and process the values, we can use the following command:

.. code-block:: none

    $ ansible -i inventory/ -m debug -a "msg={{ trident_dist_bundle }}" yellow.devops.local
    yellow.devops.local | SUCCESS => {
        "changed": false,
        "msg": [
            {
                "sha256sum": "a8af27833ada651c9d15dc29d04451250a335ae89a0d2b66bf97a787dced9956",
                "url": "https://github.com/tridentli/trident/releases/download/v1.4.5/trident-server_1.4.5_amd64.deb"
            },
            {
                "sha256sum": "15f11c986493a67e85aa9cffe6719a15a8c6a65b739a2b0adf62ce61e53f4203",
                "url": "https://github.com/tridentli/trident/releases/download/v1.4.5/trident-cli_1.4.5_amd64.deb"
            },
            {
                "sha256sum": "67f57337861098c4e9c9407592c46b04bbc2d64d85f69e8c0b9c18e8d5352ea6",
                "url": "https://github.com/tridentli/trident/releases/download/v1.4.5/trident_1.4.5_all.deb"
            },
            {
                "sha256sum": "5b06ae4a20a16a7a5e59981255ba83818f67224b68f6aaec014acf51ca9d1a44",
                "url": "https://github.com/tridentli/trident/releases/download/v1.4.5/pitchfork-data_1.9.4_all.deb"
            },
            {
                "sha256sum": "4d2f9d62989594dc5e839546da596094c16c34d129b86e4e323556f1ca1d8805",
                "url": "https://github.com/tridentli/trident/releases/download/v1.4.5/trident-wikiexport_1.4.5_amd64.deb"
            }
        ]
    }

..

.. _debugfilters:

Debugging Filter Logic
^^^^^^^^^^^^^^^^^^^^^^

Ansible supports `Filters`_ in template expressions. These use not only the
default builtin `Jinja filters`_, but also added Ansible filters and
custom filters that user can easily add.

In general, these filters take some data structure as input and perform operations
on it to produce some desired output, such as replacing strings based on regular
expressions or turning keys in dictionary into a list.

Jinja filters can be chained when maniplating complex data structures. In some
cases they must be chained to achieve the desired result.

For example, take the following example data structure, which is an
array named ``trident_site_trust_groups`` that holds dictionaries
containing a ``name``, ``initial_users``, and ``additional_lists``:

.. code-block:: yaml

    trident:
      vars:
        trident_site_trust_groups:
          - name: 'main'
            initial_users:
              - ident: 'dims'
                descr: 'DIMS Mail (no-reply)'
                email: 'noreply@{{ trident_site_email_domain }}'
              - ident: 'dittrich'
                descr: 'Dave Dittrich'
                email: 'dittrich@{{ trident_site_email_domain }}'
            additional_lists:
              - ident: 'demo'
                descr: 'LOCAL Trident Demonstration'
              - ident: 'warroom'
                descr: 'LOCAL Trust Group War Room'
              - ident: 'exercise'
                descr: 'LOCAL Trust Group Exercise Comms'
              - ident: 'events'
                descr: 'LOCAL Trust Group Social Events'

..

Start by just examining the variable using Ansible's ``debug``
module and ``var`` to select the top level variable in the
``vars`` structure.

.. code-block:: none

    $ ansible -m debug -a "var=vars.trident_site_trust_groups" yellow.devops.local
    yellow.devops.local | SUCCESS => {
        "changed": false,
        "vars.trident_site_trust_groups": [
            {
                "additional_lists": [
                    {
                        "descr": "LOCAL Trident Demonstration",
                        "ident": "demo"
                    },
                    {
                        "descr": "LOCAL Trust Group War Room",
                        "ident": "warroom"
                    },
                    {
                        "descr": "LOCAL Trust Group Exercise Comms",
                        "ident": "exercise"
                    },
                    {
                        "descr": "LOCAL Trust Group Social Events",
                        "ident": "events"
                    }
                ],
                "initial_users": [
                    {
                        "descr": "DIMS Mail (no-reply)",
                        "email": "noreply@{{ trident_site_email_domain }}",
                        "ident": "dims"
                    },
                    {
                        "descr": "Dave Dittrich",
                        "email": "dittrich@{{ trident_site_email_domain }}",
                        "ident": "dittrich"
                    }
                ],
                "name": "main",
            }
        ]
    }

..

Next, we can isolate just the ``additional_lists`` sub-dictionary:

.. code-block:: yaml

    $ ansible -m debug -a "var=vars.trident_site_trust_groups[0].additional_lists" yellow.devops.local
    yellow.devops.local | SUCCESS => {
        "changed": false,
        "vars.trident_site_trust_groups[0].additional_lists": [
            {
                "descr": "LOCAL Trident Demonstration",
                "ident": "demo"
            },
            {
                "descr": "LOCAL Trust Group War Room",
                "ident": "warroom"
            },
            {
                "descr": "LOCAL Trust Group Exercise Comms",
                "ident": "exercise"
            },
            {
                "descr": "LOCAL Trust Group Social Events",
                "ident": "events"
            }
        ]
    }

The ``map`` filter is then used to extract just the key ``ident`` from each dictionary,
followed by ``list`` to turn the extracted sub-dictionary into an array, followed
by ``sort`` to put the list in alphabetic order for good measure.

.. code-block:: yaml

    $ ansible -m debug -a msg="{{ trident_site_trust_groups[0].additional_lists|map(attribute='ident')|list|sort }}" yellow.devops.local
    yellow.devops.local | SUCCESS => {
        "changed": false,
        "msg": [
            "demo",
            "events",
            "exercise",
            "warroom"
        ]
    }

..

In an Ansible playbook, it might look like this:

.. code-block:: yaml
   :emphasize-lines: 2

    - name: Create list of defined mailing lists
      set_fact: _additional_lists={{ trident_site_trust_groups[0].additional_lists|map(attribute='ident')|list|sort }}"

    - debug: var=_additional_lists

..

This will give the following results:

.. code-block:: none
   :emphasize-lines: 8-12

    TASK [Create list of defined mailing lists] ************************************
    Monday 13 February 2017  09:20:38 -0800 (0:00:01.037)       0:00:01.093 *******
    ok: [yellow.devops.local]

    TASK [debug] *******************************************************************
    Monday 13 February 2017  09:20:38 -0800 (0:00:00.043)       0:00:01.136 *******
    ok: [yellow.devops.local] => {
        "_additional_lists": [
            "demo",
            "events",
            "exercise",
            "warroom"
        ]
    }

    PLAY RECAP *********************************************************************
    yellow.devops.local        : ok=3    changed=0    unreachable=0    failed=0

..

Our final example illustrates forced type conversion with a filter to drive the
proper logic of a boolean filter known as the *ternary* operator.  This is a
useful, but somewhat terse, operator that takes a boolean expression as the
input and produces one of two outputs based on the value of the boolean
expression. This prevents having to do two separate tasks, one with
the ``true`` conditional and a second with the ``false`` conditional.
In the example we are about to see, the goal is to produce a ternary
filter expression that results in creating a variable that will be
added to a command line invoking ``certbot-auto`` that adds the
``--staging`` option when an Ansible variable holds a boolean ``true``
value.

A conditional operation in Jinja is an expression in parentheses (``()``).
Our first attempt looks like this:

.. code-block:: none

    $ ansible -m debug -e debug=true -a 'msg={{ (debug)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "yes"
    }

..

That looks perfect! Go!

No, that is not robust. It is unwise to try something, get the result you expect, and run with
it.  Let's try setting ``debug`` to ``false`` and see what happens.

.. code-block:: none

    $ ansible -m debug -e debug=false -a 'msg={{ (debug)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "yes"
    }

..

False is true? Fake news! What is happening here? Do we need to actually do an equivalence test
using ``==`` to get the right result?  Let's try it.

.. code-block:: none

    $ ansible -m debug -e debug=false -a 'msg={{ (debug == True)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "no"
    }
    $ ansible -m debug -e debug=true -a 'msg={{ (debug == True)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "no"
    }

..

OK. Now we get the exact same result again, but this time it is the exact
*opposite* always-the-same result. What?!?!  Ansible allows us to use ``yes``,
``true``, or even ``on`` to set a boolean variable. The Gotcha here is that the
variable is being set on the command line, which sets the variable to be a
*string* rather than a *boolean*, and a non-null string (*any string*) resolves
to ``true``.

Wait! Maybe the problem is we defined ``debug=true`` instead of ``debug=True``?
That's got to be it, yes?

.. code-block:: none

    $ ansible -m debug -e "debug=True" -a 'msg={{ (debug == True)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "no"
    }

..

As the ``msg`` says, ``no``.

Let's go back to the simple ``(debug)`` test and systematically try a bunch of
alternatives and see what actually happens in real-world experimentation.

.. code-block:: none

    $ ansible -m debug -e "debug=True" -a 'msg={{ (debug)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "yes"
    }
    $ ansible -m debug -e "debug=False" -a 'msg={{ (debug)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "yes"
    }
    $ ansible -m debug -e "debug=yes" -a 'msg={{ (debug)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "yes"
    }
    $ ansible -m debug -e "debug=no" -a 'msg={{ (debug)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "yes"
    }

..

.. admonition:: Spoiler Alert

    It is not obvious at all, but the behavior hints at the problem which is
    a typing conflict between boolean and string types, combined with the way
    strings are interpreted in a conditional expression. Pretty much every
    interpreted programming language, and even some compiled languages
    without mandatory strong typing, have their own variation on this problem.
    It takes programming experience with perhaps a dozen or more programming
    languages to internalize this problem enough to reflexively avoid it it
    seems (and even then it can still bite you!) The answer is to be explicit
    about boolean typing and/or casting.

..

Jinja has a filter called ``bool`` that converts a string to a boolean the way we
expect from the Ansible documentation. Adding ``|bool`` results in the behavior
we expect:

.. code-block:: yaml

    $ ansible -m debug -e "debug=no" -a 'msg={{ (debug|bool)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "no"
    }
    $ ansible -m debug -e "debug=yes" -a 'msg={{ (debug|bool)|ternary("yes" , "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "yes"
    }
    $ ansible -m debug -e "debug=False" -a 'msg={{ (debug|bool)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "no"
    }
    $ ansible -m debug -e "debug=True" -a 'msg={{ (debug|bool)|ternary("yes" , "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "yes"
    }
    $ ansible -m debug -e "debug=off" -a 'msg={{ (debug|bool)|ternary("yes", "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "no"
    }
    $ ansible -m debug -e "debug=on" -a 'msg={{ (debug|bool)|ternary("yes" , "no") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "yes"
    }

..

OK, *that's better*!!  Now that we have the syntax down to get the logic that
we expect, we can set the ``certbot_staging`` variable they way we want:

.. code-block:: yaml

    $ ansible -m debug -e "certbot_staging=no" -a 'msg={{ (certbot_staging|bool)|ternary("--staging", "") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": ""
    }
    $ ansible -m debug -e "certbot_staging=yes" -a 'msg={{ (certbot_staging|bool)|ternary("--staging", "") }}' yellow.devops.local
    yellow.devops.local|SUCCESS => {
        "changed": false,
        "msg": "--staging"
    }

..

.. attention::

   Hopefully this shows the importance of using Ansible's ``debug`` module to develop
   tasks in playbooks such that they don't result in hidden bugs that cause silent failures
   deep within hundreds of tasks that blast by on the screen when you run a complex
   Ansible playbook. Doing this every time a complex Jinja expression, or a
   deeply nested complex data structure, will take a little extra time. But it
   is *almost guaranteed* to be *much less time* (and less stress, less friction)
   than debugging the playbook later on when something isn't working right and
   it isn't clear why. Robust coding practice is good coding practice!

..

.. _developingFilters:

Developing Custom Jinja Filters
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. todo::

   Not done yet...

..

Here is a minimal sub-set of the DIMS filters module, ``dims_filters.py``,
that implements a filter that converts an array into a string usable with
Consul for establishing an ``initial-cluster`` command line argument.

.. code-block:: python

    # vim: set ts=4 sw=4 tw=0 et :

    from netaddr import *
    import socket
    from ansible import errors

    def _initial_cluster(_list, port=2380):
        '''
        Return a comma (no spaces!) separated list of Consul initial cluster
        members from fully qualified domain names (e.g., Ansible group member
        names). The "no spaces" is because this is used as a single command line
        argument.

        a = ['node01.devops.local','node02.devops.local','node03.devops.local']
        _initial_cluster(a)
        'node01=http://node01.devops.local:2380,node02=http://node02.devops.local:2380,node03=http://node03.devops.local:2380'

        '''

        if type(_list) == type([]):
            try:
                return ','.join(
                    ['{0}=http://{1}:{2}'.format(
                        i.decode('utf-8').split('.')[0],
                        i.decode('utf-8'),
                        port) for i in _list]
                )
            except Exception as e:
                #raise errors.AnsibleFilterError(
                #    'initial_cluster() filed to convert: {0}'.format(str(e))
                #)
                return ''
        else:
            raise errors.AnsibleFilterError('Unrecognized input arguments to initial_cluster()')

    class FilterModule(object):
        '''DIMS Ansible filters.'''

        def filters(self):
            return {
                # Docker/Consul/Swarm filters
                'initial_cluster': _initial_cluster,
            }

..

Here is how it works with the ``debug`` module:

.. code-block:: none

    $ ansible -m debug -a msg="{{ groups.consul|initial_cluster() }}" node01.devops.local
    node01.devops.local | SUCCESS => {
        "changed": false,
        "msg": "node03=http://node03.devops.local:2380,node02=http://node02.devops.local:2380,node01=http://node01.devops.local:2380"
    }

..


.. _Jinja filters: http://jinja.pocoo.org/docs/2.9/templates/#list-of-builtin-filters
.. _Filters: http://docs.ansible.com/ansible/latest/playbooks_filters.html

