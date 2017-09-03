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

    $ test.runner integration/proxy
    [+] Running test integration/proxy
     ✗ [S][EV] HTTP download test (using wget, w/proxy if configured)
       (in test file integration/proxy.bats, line 16)
         `[ ! -z "$(wget -q -O - http://http.us.debian.org/debian/dists/jessie/Release | grep non-free/source/Release 2>/dev/null)" ]' failed
     ✗ [S][EV] HTTPS download test (using wget, w/proxy if configured)
       (in test file integration/proxy.bats, line 26)
         `[ ! -z "$(wget -q -O - https://packages.debian.org/jessie/amd64/0install/filelist | grep 0install 2>/dev/null)" ]' failed

    2 tests, 2 failures

..

This error will manifest itself sometimes when doing development
work on Vagrants, as can be seen here:

.. code-block:: none
   :emphasize-lines: 5-10,14

    $ cd /vm/run/purple
    $ make up && make DIMS_ANSIBLE_ARGS="--tags base" reprovision-local
    [+] Creating Vagrantfile
    . . .
    TASK [base : Only "update_cache=yes" if >3600s since last update (Debian)] ****
    Wednesday 16 August 2017  16:55:35 -0700 (0:00:01.968)       0:00:48.823 ******
    fatal: [purple.devops.local]: FAILED! => {
        "changed": false,
        "failed": true
    }

    MSG:

    Failed to update apt cache.


    RUNNING HANDLER [base : update timezone] **************************************
    Wednesday 16 August 2017  16:56:18 -0700 (0:00:43.205)       0:01:32.028 ******

    PLAY RECAP ********************************************************************
    purple.devops.local        : ok=15   changed=7    unreachable=0    failed=1

    Wednesday 16 August 2017  16:56:18 -0700 (0:00:00.000)       0:01:32.029 ******
    ===============================================================================
    base : Only "update_cache=yes" if >3600s since last update (Debian) ---- 43.21s
    . . .
    make[1]: *** [provision] Error 2
    make[1]: Leaving directory `/vm/run/purple'
    make: *** [reprovision-local] Error 2

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
            mode: 0o600
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


.. _recovering:

Recovering From Operating System Corruption
-------------------------------------------

Part of the reason for using a Python virtual environment for development
is to encapsulate the development Python and its libraries from the system
Python and its libraries, in case a failed upgrade breaks Python. Since
Python is a primary dependency of Ansible, a broken system Python is
a Very Bad Thing. |(TM)|

.. |(TM)| unicode:: U+2122

For example, the following change was attempted to try to upgrade
``pip`` packages during application of the base role. Here are
the changes:

.. code-block:: diff

    $ git diff
    diff --git a/roles/base/tasks/main.yml b/roles/base/tasks/main.yml
    index 3ce57d8..182e7d8 100644
    --- a/roles/base/tasks/main.yml
    +++ b/roles/base/tasks/main.yml
    @@ -717,7 +717,7 @@
     - name: Ensure pip installed for system python
       apt:
         name: '{{ item }}'
    -    state: installed
    +    state: latest
       with_items:
         - python-pip
       become: yes
    @@ -725,7 +725,7 @@
       tags: [ base, config ]

     - name: Ensure required system python packages present
    -  shell: 'pip install {{ item }}'
    +  shell: 'pip install -U {{ item }}'
       with_items:
         - urllib3
         - pyOpenSSL

..

Applying the ``base`` role against two systems resulted in a
series of error messages.

.. code-block:: none

    $ ansible-playbook master.yml --limit trident --tags base

    . . .

    PLAY [Configure host "purple.devops.local"] ***********************************

    . . .

    TASK [base : Ensure required system python packages present] ******************
    Thursday 17 August 2017  10:36:13 -0700 (0:00:01.879)       0:02:22.637 *******
    changed: [purple.devops.local] => (item=urllib3)
    failed: [purple.devops.local] (item=pyOpenSSL) => {
        "changed": true,
        "cmd": "pip install -U pyOpenSSL",
        "delta": "0:00:07.516760",
        "end": "2017-08-17 10:36:24.256121",
        "failed": true,
        "item": "pyOpenSSL",
        "rc": 1,
        "start": "2017-08-17 10:36:16.739361"
    }

    STDOUT:

    Downloading/unpacking pyOpenSSL from https://pypi.python.org/packages/41/bd/751560b317222ba6b6d2e7663a990ac36465aaa026621c6057db130e2faf/pyOpenSSL-17.2.0-py2.py3-none-any.whl#md5=0f8a4b784b6
    81231f03edc8dd28612df
    Downloading/unpacking six>=1.5.2 from https://pypi.python.org/packages/c8/0a/b6723e1bc4c516cb687841499455a8505b44607ab535be01091c0f24f079/six-1.10.0-py2.py3-none-any.whl#md5=3ab558cf5d4f7a72
    611d59a81a315dc8 (from pyOpenSSL)
      Downloading six-1.10.0-py2.py3-none-any.whl
    Downloading/unpacking cryptography>=1.9 (from pyOpenSSL)
      Running setup.py (path:/tmp/pip-build-FCbUwT/cryptography/setup.py) egg_info for package cryptography

        no previously-included directories found matching 'docs/_build'
        warning: no previously-included files matching '*' found under directory 'vectors'
    Downloading/unpacking idna>=2.1 (from cryptography>=1.9->pyOpenSSL)
    Downloading/unpacking asn1crypto>=0.21.0 (from cryptography>=1.9->pyOpenSSL)
    Downloading/unpacking enum34 (from cryptography>=1.9->pyOpenSSL)
      Downloading enum34-1.1.6-py2-none-any.whl
    Downloading/unpacking ipaddress (from cryptography>=1.9->pyOpenSSL)
      Downloading ipaddress-1.0.18-py2-none-any.whl
    Downloading/unpacking cffi>=1.7 (from cryptography>=1.9->pyOpenSSL)
      Running setup.py (path:/tmp/pip-build-FCbUwT/cffi/setup.py) egg_info for package cffi

    Downloading/unpacking pycparser from https://pypi.python.org/packages/8c/2d/aad7f16146f4197a11f8e91fb81df177adcc2073d36a17b1491fd09df6ed/pycparser-2.18.tar.gz#md5=72370da54358202a60130e223d4
    88136 (from cffi>=1.7->cryptography>=1.9->pyOpenSSL)
      Running setup.py (path:/tmp/pip-build-FCbUwT/pycparser/setup.py) egg_info for package pycparser

        warning: no previously-included files matching 'yacctab.*' found under directory 'tests'
        warning: no previously-included files matching 'lextab.*' found under directory 'tests'
        warning: no previously-included files matching 'yacctab.*' found under directory 'examples'
        warning: no previously-included files matching 'lextab.*' found under directory 'examples'
    Installing collected packages: pyOpenSSL, six, cryptography, idna, asn1crypto, enum34, ipaddress, cffi, pycparser
      Found existing installation: pyOpenSSL 0.14
        Not uninstalling pyOpenSSL at /usr/lib/python2.7/dist-packages, owned by OS
      Found existing installation: six 1.8.0
        Not uninstalling six at /usr/lib/python2.7/dist-packages, owned by OS
      Found existing installation: cryptography 0.6.1
        Not uninstalling cryptography at /usr/lib/python2.7/dist-packages, owned by OS
      Running setup.py install for cryptography

        Installed /tmp/pip-build-FCbUwT/cryptography/cffi-1.10.0-py2.7-linux-x86_64.egg
        Traceback (most recent call last):
          File "<string>", line 1, in <module>
          File "/tmp/pip-build-FCbUwT/cryptography/setup.py", line 312, in <module>
            **keywords_with_side_effects(sys.argv)
          File "/usr/lib/python2.7/distutils/core.py", line 111, in setup
            _setup_distribution = dist = klass(attrs)
          File "/usr/lib/python2.7/dist-packages/setuptools/dist.py", line 266, in __init__
            _Distribution.__init__(self,attrs)
          File "/usr/lib/python2.7/distutils/dist.py", line 287, in __init__
            self.finalize_options()
          File "/usr/lib/python2.7/dist-packages/setuptools/dist.py", line 301, in finalize_options
            ep.load()(self, ep.name, value)
          File "/usr/lib/python2.7/dist-packages/pkg_resources.py", line 2190, in load
            ['__name__'])
        ImportError: No module named setuptools_ext
        Complete output from command /usr/bin/python -c "import setuptools, tokenize;__file__='/tmp/pip-build-FCbUwT/cryptography/setup.py';exec(compile(getattr(tokenize, 'open', open)(__file__)
    .read().replace('\r\n', '\n'), __file__, 'exec'))" install --record /tmp/pip-qKjzie-record/install-record.txt --single-version-externally-managed --compile:


    Installed /tmp/pip-build-FCbUwT/cryptography/cffi-1.10.0-py2.7-linux-x86_64.egg

    Traceback (most recent call last):

      File "<string>", line 1, in <module>

      File "/tmp/pip-build-FCbUwT/cryptography/setup.py", line 312, in <module>

        **keywords_with_side_effects(sys.argv)

      File "/usr/lib/python2.7/distutils/core.py", line 111, in setup

        _setup_distribution = dist = klass(attrs)

      File "/usr/lib/python2.7/dist-packages/setuptools/dist.py", line 266, in __init__

        _Distribution.__init__(self,attrs)

      File "/usr/lib/python2.7/distutils/dist.py", line 287, in __init__

        self.finalize_options()

      File "/usr/lib/python2.7/dist-packages/setuptools/dist.py", line 301, in finalize_options

        ep.load()(self, ep.name, value)

      File "/usr/lib/python2.7/dist-packages/pkg_resources.py", line 2190, in load

        ['__name__'])

    ImportError: No module named setuptools_ext

    ----------------------------------------
      Can't roll back cryptography; was not uninstalled
    Cleaning up...
    Command /usr/bin/python -c "import setuptools, tokenize;__file__='/tmp/pip-build-FCbUwT/cryptography/setup.py';exec(compile(getattr(tokenize, 'open', open)(__file__).read().replace('\r\n', '
    \n'), __file__, 'exec'))" install --record /tmp/pip-qKjzie-record/install-record.txt --single-version-externally-managed --compile failed with error code 1 in /tmp/pip-build-FCbUwT/cryptogra
    phy
    Storing debug log for failure in /root/.pip/pip.log

    . . .

    PLAY RECAP ********************************************************************
    purple.devops.local        : ok=60   changed=35   unreachable=0    failed=1

    Thursday 17 August 2017  10:36:29 -0700 (0:00:00.001)       0:02:38.799 *******
    ===============================================================================
    base : Ensure required system python packages present ------------------ 16.16s
    base : Ensure dims (system-level) subdirectories exist ----------------- 15.85s
    base : Only "update_cache=yes" if >3600s since last update (Debian) ----- 5.65s
    base : conditional restart docker --------------------------------------- 5.60s
    base : Make sure required APT packages are present (Debian) ------------- 2.14s
    base : Clean up dnsmasq build artifacts --------------------------------- 2.09s
    base : Make sure blacklisted packages are absent (Debian) --------------- 2.03s
    base : Check to see if https_proxy is working --------------------------- 1.99s
    base : Log start of 'base' role ----------------------------------------- 1.95s
    base : Make backports present for APT on Debian jessie ------------------ 1.89s
    base : Ensure pip installed for system python --------------------------- 1.88s
    base : Only "update_cache=yes" if >3600s since last update -------------- 1.85s
    base : Make dbus-1 development libraries present ------------------------ 1.85s
    base : iptables v4 rules (Debian) --------------------------------------- 1.84s
    base : iptables v6 rules (Debian) --------------------------------------- 1.84s
    base : Make full dnsmasq package present (Debian, not Trusty) ----------- 1.82s
    base : Create base /etc/hosts file (Debian, RedHat, CoreOS) ------------- 1.64s
    base : Make /etc/rsyslog.d/49-consolidation.conf present ---------------- 1.63s
    base : Make dnsmasq configuration present on Debian --------------------- 1.60s
    base : Ensure DIMS system shell init hook is present (Debian, CoreOS) --- 1.56s

..

The ``base`` role is supposed to ensure the operating system has the
fundamental settings and pre-requisites necessary for all other DIMS
roles, so applying that role should *hopefully* fix things, right?

.. code-block:: none

    $ ansible-playbook master.yml --limit trident --tags base

    . . .

    PLAY [Configure host "purple.devops.local"] ***********************************

    . . .

    TASK [base : Make sure blacklisted packages are absent (Debian)] **************
    Thursday 17 August 2017  11:05:08 -0700 (0:00:01.049)       0:00:30.456 *******
    ...ignoring
    An exception occurred during task execution. To see the full traceback, use
    -vvv. The error was: AttributeError: 'FFI' object has no attribute 'new_allocator'
    failed: [purple.devops.local] (item=[u'modemmanager', u'resolvconf', u'sendmail']) => {
        "failed": true,
        "item": [
            "modemmanager",
            "resolvconf",
            "sendmail"
        ],
        "module_stderr": "Traceback (most recent call last):\n  File \"/tmp/ansible_ehzfMx/
        ansible_module_apt.py\", line 239, in <module>\n    from ansible.module_utils.urls import fetch_url\n
    File \"/tmp/ansible_ehzfMx/ansible_modlib.zip/ansible/module_utils/urls.py\", line 153,
    in <module>\n  File \"/usr/local/lib/python2.7/dist-packages/urllib3/contrib/pyopenssl.py\", line 46,
    in <module>\n    import OpenSSL.SSL\n  File \"/usr/local/lib/python2.7/dist-packages/OpenSSL/__init__.py\",
    line 8, in <module>\n    from OpenSSL import rand, crypto, SSL\n  File \"/usr/local/lib/
    python2.7/dist-packages/OpenSSL/rand.py\", line 10, in <module>\n    from OpenSSL._util
    import (\n  File \"/usr/local/lib/python2.7/dist-packages/OpenSSL/_util.py\", line 18, in
    <module>\n    no_zero_allocator = ffi.new_allocator(should_clear_after_alloc=False)\n
    AttributeError: 'FFI' object has no attribute 'new_allocator'\n",
        "module_stdout": "",
        "rc": 1
    }

    MSG:

    MODULE FAILURE


    TASK [base : Only "update_cache=yes" if >3600s since last update (Debian)] ****
    Thursday 17 August 2017  11:05:10 -0700 (0:00:01.729)       0:00:32.186 *******
    An exception occurred during task execution. To see the full traceback, use -vvv.
    The error was: AttributeError: 'FFI' object has no attribute 'new_allocator'
    fatal: [purple.devops.local]: FAILED! => {
        "changed": false,
        "failed": true,
        "module_stderr": "Traceback (most recent call last):\n  File \"/tmp/ansible_ganqlZ/
        ansible_module_apt.py\", line 239, in <module>\n    from ansible.module_utils.urls import fetch_url\n
    File \"/tmp/ansible_ganqlZ/ansible_modlib.zip/ansible/module_utils/urls.py\", line 153, in
    <module>\n  File \"/usr/local/lib/python2.7/dist-packages/urllib3/contrib/pyopenssl.py\", line 46,
    in <module>\n    import OpenSSL.SSL\n  File \"/usr/local/lib/python2.7/dist-packages/
    OpenSSL/__init__.py\", line 8, in <module>\n    from OpenSSL import rand, crypto, SSL\n
    File \"/usr/local/lib/python2.7/dist-packages/OpenSSL/rand.py\", line 10, in <module>\n
    from OpenSSL._util import (\n  File \"/usr/local/lib/python2.7/dist-packages/OpenSSL/_util.py\",
    line 18, in <module>\n    no_zero_allocator = ffi.new_allocator(should_clear_after_alloc=False)\n
    AttributeError: 'FFI' object has no attribute 'new_allocator'\n",
        "module_stdout": "",
        "rc": 1
    }

    MSG:

    MODULE FAILURE


    RUNNING HANDLER [base : update timezone] **************************************
    Thursday 17 August 2017  11:05:11 -0700 (0:00:01.530)       0:00:33.716 *******

    PLAY RECAP ********************************************************************
    purple.devops.local        : ok=14   changed=7    unreachable=0    failed=1

    Thursday 17 August 2017  11:05:11 -0700 (0:00:00.001)       0:00:33.717 *******
    ===============================================================================
    base : Log start of 'base' role ----------------------------------------- 1.88s
    base : Make sure blacklisted packages are absent (Debian) --------------- 1.73s
    base : Create base /etc/hosts file (Debian, RedHat, CoreOS) ------------- 1.55s
    base : Only "update_cache=yes" if >3600s since last update (Debian) ----- 1.53s
    base : Set timezone variables (Debian) ---------------------------------- 1.53s
    base : iptables v6 rules (Debian) --------------------------------------- 1.48s
    base : iptables v4 rules (Debian) --------------------------------------- 1.48s
    base : Ensure getaddrinfo configuration is present (Debian) ------------- 1.48s
    base : Check to see if dims.logger exists yet --------------------------- 1.31s
    base : Set domainname (Debian, CoreOS) ---------------------------------- 1.17s
    base : Check to see if gpk-update-viewer is running on Ubuntu ----------- 1.16s
    base : Set hostname (runtime) (Debian, CoreOS) -------------------------- 1.16s
    base : Make /etc/hostname present (Debian, CoreOS) ---------------------- 1.16s
    base : Disable IPv6 in kernel on non-CoreOS ----------------------------- 1.16s
    debug : include --------------------------------------------------------- 1.07s
    base : iptables v4 rules (CoreOS) --------------------------------------- 1.06s
    base : iptables v6 rules (CoreOS) --------------------------------------- 1.06s
    debug : debug ----------------------------------------------------------- 1.05s
    debug : debug ----------------------------------------------------------- 1.05s
    debug : debug ----------------------------------------------------------- 1.05s

..

Since Debian ``apt`` is a Python program, it requires Python to install
packages. The Python packages are corrupted, so Python will not work
properly. This creates a deadlock condition.  There is another way to
install Python packages, however, so it can be used via Ansible ad-hoc
mode:

.. code-block:: none

    $ ansible -m shell --become -a 'easy_install -U cffi' trident
    yellow.devops.local | SUCCESS | rc=0 >>
    Searching for cffi
    Reading https://pypi.python.org/simple/cffi/
    Best match: cffi 1.10.0
    Downloading https://pypi.python.org/packages/5b/b9/790f8eafcdab455bcd3bd908161f802c9ce5adbf702a83aa7712fcc345b7/cffi-1.10.0.tar.gz#md5=2b5fa41182ed0edaf929a789e602a070
    Processing cffi-1.10.0.tar.gz
    Writing /tmp/easy_install-RmOJBU/cffi-1.10.0/setup.cfg
    Running cffi-1.10.0/setup.py -q bdist_egg --dist-dir /tmp/easy_install-RmOJBU/cffi-1.10.0/egg-dist-tmp-lNCOck
    compiling '_configtest.c':
    __thread int some_threadlocal_variable_42;

    x86_64-linux-gnu-gcc -pthread -DNDEBUG -g -fwrapv -O2 -Wall -Wstrict-prototypes -fno-strict-aliasing -D_FORTIFY_SOURCE=2 -g -fstack-protector-strong -Wformat -Werror=format-security -fPIC -c
     _configtest.c -o _configtest.o
    success!
    removing: _configtest.c _configtest.o
    compiling '_configtest.c':
    int main(void) { __sync_synchronize(); return 0; }

    x86_64-linux-gnu-gcc -pthread -DNDEBUG -g -fwrapv -O2 -Wall -Wstrict-prototypes -fno-strict-aliasing -D_FORTIFY_SOURCE=2 -g -fstack-protector-strong -Wformat -Werror=format-security -fPIC -c
     _configtest.c -o _configtest.o
    x86_64-linux-gnu-gcc -pthread _configtest.o -o _configtest
    success!
    removing: _configtest.c _configtest.o _configtest
    Adding cffi 1.10.0 to easy-install.pth file

    Installed /usr/local/lib/python2.7/dist-packages/cffi-1.10.0-py2.7-linux-x86_64.egg
    Processing dependencies for cffi
    Finished processing dependencies for cffi

    purple.devops.local | SUCCESS | rc=0 >>
    Searching for cffi
    Reading https://pypi.python.org/simple/cffi/
    Best match: cffi 1.10.0
    Downloading https://pypi.python.org/packages/5b/b9/790f8eafcdab455bcd3bd908161f802c9ce5adbf702a83aa7712fcc345b7/cffi-1.10.0.tar.gz#md5=2b5fa41182ed0edaf929a789e602a070
    Processing cffi-1.10.0.tar.gz
    Writing /tmp/easy_install-fuS4hd/cffi-1.10.0/setup.cfg
    Running cffi-1.10.0/setup.py -q bdist_egg --dist-dir /tmp/easy_install-fuS4hd/cffi-1.10.0/egg-dist-tmp-nOgko4
    compiling '_configtest.c':
    __thread int some_threadlocal_variable_42;

    x86_64-linux-gnu-gcc -pthread -DNDEBUG -g -fwrapv -O2 -Wall -Wstrict-prototypes -fno-strict-aliasing -D_FORTIFY_SOURCE=2 -g -fstack-protector-strong -Wformat -Werror=format-security -fPIC -c
     _configtest.c -o _configtest.o
    success!
    removing: _configtest.c _configtest.o
    compiling '_configtest.c':
    int main(void) { __sync_synchronize(); return 0; }

    x86_64-linux-gnu-gcc -pthread -DNDEBUG -g -fwrapv -O2 -Wall -Wstrict-prototypes -fno-strict-aliasing -D_FORTIFY_SOURCE=2 -g -fstack-protector-strong -Wformat -Werror=format-security -fPIC -c
     _configtest.c -o _configtest.o
    x86_64-linux-gnu-gcc -pthread _configtest.o -o _configtest
    success!
    removing: _configtest.c _configtest.o _configtest
    Adding cffi 1.10.0 to easy-install.pth file

    Installed /usr/local/lib/python2.7/dist-packages/cffi-1.10.0-py2.7-linux-x86_64.egg
    Processing dependencies for cffi
    Finished processing dependencies for cffi

..

Now we can back out the addition of the ``-U`` flag that caused
the corruption and apply the base role to the two hosts using
the ``master.yml`` playbook.

.. code-block:: none

    $ ansible-playbook master.yml --limit trident --tags base

    . . .

    PLAY [Configure host "purple.devops.local"] ***********************************

    . . .

    PLAY [Configure host "yellow.devops.local"] ***********************************

    . . .

    PLAY RECAP ********************************************************************
    purple.devops.local        : ok=136  changed=29   unreachable=0    failed=0
    yellow.devops.local        : ok=139  changed=53   unreachable=0    failed=0

    Thursday 17 August 2017  11:20:08 -0700 (0:00:01.175)       0:10:03.307 *******
    ===============================================================================
    base : Make defined bats tests present --------------------------------- 29.18s
    base : Make defined bats tests present --------------------------------- 28.95s
    base : Ensure dims (system-level) subdirectories exist ----------------- 15.89s
    base : Ensure dims (system-level) subdirectories exist ----------------- 15.84s
    base : Ensure required system python packages present ------------------- 8.81s
    base : Make sure common (non-templated) BASH scripts are present -------- 8.79s
    base : Make sure common (non-templated) BASH scripts are present -------- 8.74s
    base : Ensure required system python packages present ------------------- 8.71s
    base : Make subdirectories for test categories present ------------------ 6.84s
    base : Make links to helper functions present --------------------------- 6.83s
    base : Make subdirectories for test categories present ------------------ 6.83s
    base : Make links to helper functions present --------------------------- 6.81s
    base : Ensure bashrc additions are present ------------------------------ 4.63s
    base : Ensure bashrc additions are present ------------------------------ 4.59s
    base : Only "update_cache=yes" if >3600s since last update (Debian) ----- 4.45s
    base : Make sure common (non-templated) Python scripts are present ------ 3.77s
    base : Make sure common (non-templated) Python scripts are present ------ 3.77s
    base : conditional restart docker --------------------------------------- 3.17s
    base : Make sure common (templated) scripts are present ----------------- 2.96s
    base : Make sure common (templated) scripts are present ----------------- 2.94s

..

In this case, the systems are now back to a functional state and the
disruptive change backed out. Were these Vagrants, the problem of a
broken system is lessened, so testing should *always* be done first
on throw-away VMs. But on those occassions where something goes wrong
on "production" hosts, Ansible ad-hoc mode is a powerful debugging
and corrective capability.
