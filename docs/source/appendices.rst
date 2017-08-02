.. _appendices

Appendices
==========

.. _restart_proxy:

Quick Steps to Restarting Squid Proxy Container
-----------------------------------------------

Downloading and installing several hundred packages per host while testing
provisioning of multiple Vagrant virtual machines can take several hours to
perform over a 1-5 Mbps network connection. Even a single Vagrant can take
around 45 minutes to fully provision after a ``vagrant destroy``. Since
this task may need to be done over and over again, even for just one
system, the process becomes very tedious and time consuming.

To minimize the number of remote downloads, a local proxy can help immensely.
The DIMS project utilizes a ``squid-deb-proxy`` running in a Docker container
on VM host systems to allow all of the local VMs to take advantage of a single
cacheing proxy on the host.  This significantly improves performance (cutting
the time down to just a few minutes), but this comes at a cost in occassional
instability due to the combination of ``iptables`` firewall rules that must
contain a ``DOCKER`` chain for Docker, which attempts to keep the
``squid-deb-proxy`` container running across reboots of the VM host can result
in the the container effectively "hanging" from time to time.  This manifests
as a random failure in an Ansible task that is trying to use the configured
proxy (e.g., see the ``python-virtualenv`` build failure in Section
:ref:`_using_dims_functions_in_bats`.)

A ``bats`` test exists to test the proxy:

.. code-block:: none

    $ test.runner --level '*' --match proxy
    [+] Running test integration/proxy
     ✗ [S][EV] HTTP download test (using wget, w/proxy if configured)
       (in test file integration/proxy.bats, line 16)
         `[ ! -z "$(wget -q -O - http://http.us.debian.org/debian/dists/jessie/Release | grep non-free/source/Release 2>/dev/null)" ]' failed
     ✗ [S][EV] HTTPS download test (using wget, w/proxy if configured)
       (in test file integration/proxy.bats, line 26)
         `[ ! -z "$(wget -q -O - https://packages.debian.org/jessie/amd64/0install/filelist | grep 0install 2>/dev/null)" ]' failed

    2 tests, 2 failures

..

When it fails like this, it usually means that ``iptables`` must be restarted,
followed by restarting the ``docker`` service. That usually is enough to fix
the problem. If not, it may be necessary to also restart the ``squid-deb-proxy``
container.

.. note::

    The cause of this the recreation of the ``DOCKER`` chain, which removes the rules added by
    Docker, when restarting just the ``iptables-persistent`` service as can be seen here:

    .. code-block:: none

        $ sudo iptables -nvL | grep "Chain DOCKER"
        Chain DOCKER (2 references)
        Chain DOCKER-ISOLATION (1 references)
        $ sudo iptables-persistent restart
        sudo: iptables-persistent: command not found
        $ sudo service iptables-persistent restart
         * Loading iptables rules...
         *  IPv4...
         *  IPv6...
           ...done.
        $ sudo iptables -nvL | grep "Chain DOCKER"
        Chain DOCKER (0 references)

    ..

    Restarting the ``docker`` service will restore the rules for containers
    that Docker is keeping running across restarts.

    .. code-block:: none

        $ sudo service docker restart
        docker stop/waiting
        docker start/running, process 18276
        $ sudo iptables -nvL | grep "Chain DOCKER"
        Chain DOCKER (2 references)
        Chain DOCKER-ISOLATION (1 references)

    ..

    The solution for this is to notify a special handler that conditionally
    restarts the ``docker`` service after restarting ``iptables`` in order to
    re-establish the proper firewall rules. The handler is shown here:

    .. code-block:: yaml
       :emphasize-lines: 1

        - name: conditional restart docker
          service: name=docker state=restarted
          when: hostvars[inventory_hostname].ansible_docker0 is defined

    ..

    Use of the handler (from ``roles/base/tasks/main.yml``) is shown here:

    .. code-block:: yaml
       :emphasize-lines: 20,21

        - name: iptables v4 rules (Debian)
          template:
            src: '{{ item }}'
            dest: /etc/iptables/rules.v4
            owner: '{{ root_user }}'
            group: '{{ root_group }}'
            mode: '{{ mode_0600 }}'
            validate: '/sbin/iptables-restore --test %s'
          with_first_found:
            - files:
                - '{{ iptables_rules }}'
                - rules.v4.{{ inventory_hostname }}.j2
                - rules.v4.category-{{ category }}.j2
                - rules.v4.deployment-{{ deployment }}.j2
                - rules.v4.j2
              paths:
                - '{{ dims_private }}/roles/{{ role_name }}/templates/iptables/'
                - iptables/
          notify:
            - "restart iptables ({{ ansible_distribution }}/{{ ansible_distribution_release }})"
            - "conditional restart docker"
          become: yes
          when: ansible_os_family == "Debian"
          tags: [ base, config, iptables ]

    ..

    A tag ``iptables`` exists to allow regeneration of the ``iptables`` rules and
    perform the proper restarting sequence, which should be used instead of just
    restarting the ``iptables-persistent`` service manually. Use ``ansible-playbook``
    instead (e.g., ``run.playbook --tags iptables``) after making changes to
    variables that affect ``iptables`` rules.

..

.. code-block:: none

    $ cd $GIT/dims-dockerfiles/dockerfiles/squid-deb-proxy

    $ for S in iptables-persistent docker; do sudo service $S restart; done
     * Loading iptables rules...
     *  IPv4...
     *  IPv6...
       ...done.
    docker stop/waiting
    docker start/running, process 22065

    $ make rm
    docker stop dims.squid-deb-proxy
    test.runner -dims.squid-deb-proxy
    docker rm dims.squid-deb-proxy
    -dims.squid-deb-proxy

    $ make daemon
    docker run \
              --name dims.squid-deb-proxy \
              --restart unless-stopped \
              -v /vm/cache/apt:/cachedir -p 127.0.0.1:8000:8000 squid-deb-proxy:0.7 2>&1 >/dev/null &
    2017/07/22 19:31:29| strtokFile: /etc/squid-deb-proxy/autogenerated/pkg-blacklist-regexp.acl not found
    2017/07/22 19:31:29| Warning: empty ACL: acl blockedpkgs urlpath_regex "/etc/squid-deb-proxy/autogenerated/pkg-blacklist-regexp.acl"

..

The test should now succeed:

.. code-block:: none

    $ test.runner --level '*' --match proxy
    [+] Running test integration/proxy
     ✓ [S][EV] HTTP download test (using wget, w/proxy if configured)
     ✓ [S][EV] HTTPS download test (using wget, w/proxy if configured)

    2 tests, 0 failures

..
