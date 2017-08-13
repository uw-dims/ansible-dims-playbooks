.. _backups:

Backups and Restoration
=======================

A good part of ongoing system administration is producing backups of files and
database content that is created after initial system setup and that cannot be
replaced by simply running a playbook again.  Things like copies of Git
repositories and the content of the PostgreSQL database used by the Trident
portal are two primary sets of data that you will want to backup, and possibly
more importantly to restore in case of a drive failure or accidental deletion.

Built into the playbooks for Letsencrypt certificate installation as part
of the ``nginx`` role, and Trident database tables as part of the
``trident-core`` role, are mechanisms for automatic restoration from
backups.  This is very handy for development and testing using
Vagrant virtual machines, since these are typically destroyed and
rebuilt regularly. Restoring from backups helps more quickly get
back to a functional state that possibly would trigger certificate
generation limits (in the case of ``nginx`` and Letsencrypt) or
a lot of manual actions in a graphical user interface to set up user
accounts (in the case of the Trident portal).

This section will go through these backup and restoration utilities
and how to use them.

.. _backup_directories:

Backup Directories and Files
----------------------------

A directory is created on DIMS systems to be used for storing backup files.
In production, these files would be copied to tape, to encrypted external
storage (e.g., AWS buckets), to external removable hard drives, etc.

The location for storing these files is ``/opt/dims/backups`` (pointed
to by the Ansible global variable ``dims_backups``.) After following
the steps outlined in Chapter :ref:`bootstrapping`, this directory
will be empty:

.. code-block:: none

    $ tree /opt/dims/backups/
    /opt/dims/backups/

    0 directories, 0 files

..

After completing the steps in Chapter :ref:`creating_vms`, there will be
two Trident portals (one for development/testing, and the other for production
use) that have initial content put in place by the ``trident-configure`` role.

.. caution::

   The ``trident-configure`` role is not entirely idempotent in relation to
   a running system that is manipulated manually by users and administrators.
   That is to say, any configuration changes made through the ``tcli`` command
   line interface, or the Trident portal interface, are not directly reflected
   in the Ansible inventory used to bootstrap the Trident portals. That means that
   any changes made will be reverted by the ``trident-configure`` role to what
   the inventory says they should be (and any new trust groups or mailing lists
   created manually will not be put back by the ``trident-configure`` role, which
   is unaware they exist).

   This is an area that needs further work to be completely idempotent for long-term
   production systems. In the mean time, be aware of these limitations and only make
   configuration changes by setting variables in the inventory files and create
   database backups so as to keep copies of database content.

..

.. _creating_a_backup:

Creating a Backup
-----------------

The playbook ``playbooks/postgresql_backup.yml`` exists to easily perform the backup
operation using ``ansible-playbook``.  The playbook is very simple, as seen here:

.. literalinclude:: ../../playbooks/postgresql_backup.yml

By default, the playbook is applied to the ``trident`` group:

.. code-block:: none

    $ ansible --list-hosts trident
      hosts (2):
        yellow.devops.develop
        purple.devops.develop
    $ ansible-playbook /opt/dims/git/ansible-dims-playbooks/playbooks/postgresql_backup.yml

    PLAY [Backup trident postgresql database] *************************************

    TASK [include] ****************************************************************
    Saturday 12 August 2017  20:50:29 -0700 (0:00:00.064)       0:00:00.064 *******
    included: /opt/dims/git/ansible-dims-playbooks/tasks/postgresql_backup.yml for
    yellow.devops.develop, purple.devops.develop

    TASK [Define local postgresql backup directory] *******************************
    Saturday 12 August 2017  20:50:30 -0700 (0:00:01.199)       0:00:01.264 *******
    ok: [yellow.devops.develop]
    ok: [purple.devops.develop]

    TASK [debug] ******************************************************************
    Saturday 12 August 2017  20:50:31 -0700 (0:00:01.129)       0:00:02.394 *******
    ok: [yellow.devops.develop] => {
        "postgresql_backup_dir": "/opt/dims/backups/yellow.devops.develop"
    }
    ok: [purple.devops.develop] => {
        "postgresql_backup_dir": "/opt/dims/backups/purple.devops.develop"
    }

    TASK [Define backup_ts timestamp] *********************************************
    Saturday 12 August 2017  20:50:32 -0700 (0:00:01.125)       0:00:03.520 *******
    ok: [yellow.devops.develop]
    ok: [purple.devops.develop]

    TASK [Define postgresql_backup_file] ******************************************
    Saturday 12 August 2017  20:50:34 -0700 (0:00:02.161)       0:00:05.681 *******
    ok: [yellow.devops.develop]
    ok: [purple.devops.develop]

    TASK [Ensure local postgresql backup directory exists] ************************
    Saturday 12 August 2017  20:50:35 -0700 (0:00:01.162)       0:00:06.843 *******
    changed: [purple.devops.develop -> 127.0.0.1]
    changed: [yellow.devops.develop -> 127.0.0.1]

    TASK [Create remote temporary directory] **************************************
    Saturday 12 August 2017  20:50:37 -0700 (0:00:01.463)       0:00:08.307 *******
    changed: [purple.devops.develop]
    changed: [yellow.devops.develop]

    TASK [Define _tmpdir variable] ************************************************
    Saturday 12 August 2017  20:50:38 -0700 (0:00:01.635)       0:00:09.943 *******
    ok: [yellow.devops.develop]
    ok: [purple.devops.develop]

    TASK [Create backup of postgresql database] ***********************************
    Saturday 12 August 2017  20:50:40 -0700 (0:00:01.129)       0:00:11.072 *******
    changed: [purple.devops.develop]
    changed: [yellow.devops.develop]

    TASK [Fetch postgresql backup file] *******************************************
    Saturday 12 August 2017  20:50:42 -0700 (0:00:02.076)       0:00:13.148 *******
    changed: [purple.devops.develop]
    changed: [yellow.devops.develop]

    TASK [Set backup ownership] ***************************************************
    Saturday 12 August 2017  20:50:43 -0700 (0:00:01.577)       0:00:14.726 *******
    changed: [yellow.devops.develop -> 127.0.0.1]
    changed: [purple.devops.develop -> 127.0.0.1]

    TASK [Remove temporary directory] *********************************************
    Saturday 12 August 2017  20:50:45 -0700 (0:00:01.317)       0:00:16.044 *******
    changed: [yellow.devops.develop]
    changed: [purple.devops.develop]

    PLAY RECAP ********************************************************************
    purple.devops.develop            : ok=12   changed=6    unreachable=0    failed=0
    yellow.devops.develop            : ok=12   changed=6    unreachable=0    failed=0

    Saturday 12 August 2017  20:50:46 -0700 (0:00:01.344)       0:00:17.388 *******
    ===============================================================================
    Define backup_ts timestamp ---------------------------------------------- 2.16s
    Create backup of postgresql database ------------------------------------ 2.08s
    Create remote temporary directory --------------------------------------- 1.64s
    Fetch postgresql backup file -------------------------------------------- 1.58s
    Ensure local postgresql backup directory exists ------------------------- 1.46s
    Remove temporary directory ---------------------------------------------- 1.34s
    Set backup ownership ---------------------------------------------------- 1.32s
    include ----------------------------------------------------------------- 1.20s
    Define postgresql_backup_file ------------------------------------------- 1.16s
    Define local postgresql backup directory -------------------------------- 1.13s
    Define _tmpdir variable ------------------------------------------------- 1.13s
    debug ------------------------------------------------------------------- 1.13s

..

The backups will now show up, each in their own host's directory tree:

.. code-block:: none

    $ tree /opt/dims/backups/
    /opt/dims/backups/
    ├── purple.devops.develop
    │   └── postgresql_2017-08-12T20:50:33PDT.pgdmp.bz2
    └── yellow.devops.develop
        └── postgresql_2017-08-12T20:50:33PDT.pgdmp.bz2

    2 directories, 2 files

..

There is a similar playbook for backing up the ``/etc/letsencrypt`` directory
with all of its certificate registration and archive history data.

.. literalinclude:: ../../playbooks/letsencrypt_backup.yml

The default for this playbook is the ``nginx`` group. If you do not have
an ``nginx`` group, or want to select a different group, define the variable
``host`` on the command line:

.. code-block:: none

    $ ansible-playbook $PBR/playbooks/letsencrypt_backup.yml -e host=trident

    PLAY [Backup letsencrypt certificate store] ***********************************

    TASK [include] ****************************************************************
    Saturday 12 August 2017  22:55:26 -0700 (0:00:00.063)       0:00:00.063 *******
    included: /opt/dims/git/ansible-dims-playbooks/tasks/letsencrypt_backup.yml
    for yellow.devops.develop, purple.devops.develop

    TASK [Define _default_backups_dir] ********************************************
    Saturday 12 August 2017  22:55:27 -0700 (0:00:01.200)       0:00:01.264 *******
    ok: [yellow.devops.develop]
    ok: [purple.devops.develop]

    TASK [Create temporary directory for cert backup] *****************************
    Saturday 12 August 2017  22:55:28 -0700 (0:00:01.126)       0:00:02.391 *******
    changed: [yellow.devops.develop]
    changed: [purple.devops.develop]

    TASK [Define _tmpdir variable] ************************************************
    Saturday 12 August 2017  22:55:30 -0700 (0:00:01.655)       0:00:04.046 *******
    ok: [yellow.devops.develop]
    ok: [purple.devops.develop]

    TASK [Define backup_ts timestamp] *********************************************
    Saturday 12 August 2017  22:55:31 -0700 (0:00:01.123)       0:00:05.170 *******
    ok: [yellow.devops.develop]
    ok: [purple.devops.develop]

    TASK [Define certbot_backup_file] *********************************************
    Saturday 12 August 2017  22:55:33 -0700 (0:00:02.157)       0:00:07.328 *******
    ok: [yellow.devops.develop]
    ok: [purple.devops.develop]

    TASK [Create backup of letsencrypt certificates] ******************************
    Saturday 12 August 2017  22:55:34 -0700 (0:00:01.123)       0:00:08.452 *******
    changed: [yellow.devops.develop]
    changed: [purple.devops.develop]

    TASK [Ensure local cert directory exists] *************************************
    Saturday 12 August 2017  22:55:36 -0700 (0:00:01.600)       0:00:10.052 *******
    ok: [purple.devops.develop -> 127.0.0.1]
    ok: [yellow.devops.develop -> 127.0.0.1]

    TASK [Fetch backup copy of letsencrypt directory] *****************************
    Saturday 12 August 2017  22:55:38 -0700 (0:00:01.465)       0:00:11.517 *******
    changed: [yellow.devops.develop]
    changed: [purple.devops.develop]

    TASK [Note success in backing up certs] ***************************************
    Saturday 12 August 2017  22:55:39 -0700 (0:00:01.488)       0:00:13.006 *******
    ok: [yellow.devops.develop]
    ok: [purple.devops.develop]

    TASK [Set backup ownership] ***************************************************
    Saturday 12 August 2017  22:55:40 -0700 (0:00:01.138)       0:00:14.145 *******
    changed: [yellow.devops.develop -> 127.0.0.1]
    changed: [purple.devops.develop -> 127.0.0.1]

    TASK [Remove temporary directory] *********************************************
    Saturday 12 August 2017  22:55:41 -0700 (0:00:01.321)       0:00:15.467 *******
    changed: [yellow.devops.develop]
    changed: [purple.devops.develop]

    TASK [fail] *******************************************************************
    Saturday 12 August 2017  22:55:43 -0700 (0:00:01.348)       0:00:16.816 *******
    skipping: [yellow.devops.develop]
    skipping: [purple.devops.develop]

    PLAY RECAP ********************************************************************
    purple.devops.develop            : ok=12   changed=5    unreachable=0    failed=0
    yellow.devops.develop            : ok=12   changed=5    unreachable=0    failed=0

    Saturday 12 August 2017  22:55:44 -0700 (0:00:01.103)       0:00:17.920 *******
    ===============================================================================
    Define backup_ts timestamp ---------------------------------------------- 2.16s
    Create temporary directory for cert backup ------------------------------ 1.66s
    Create backup of letsencrypt certificates ------------------------------- 1.60s
    Fetch backup copy of letsencrypt directory ------------------------------ 1.49s
    Ensure local cert directory exists -------------------------------------- 1.47s
    Remove temporary directory ---------------------------------------------- 1.35s
    Set backup ownership ---------------------------------------------------- 1.32s
    include ----------------------------------------------------------------- 1.20s
    Note success in backing up certs ---------------------------------------- 1.14s
    Define _default_backups_dir --------------------------------------------- 1.13s
    Define certbot_backup_file ---------------------------------------------- 1.12s
    Define _tmpdir variable ------------------------------------------------- 1.12s
    fail -------------------------------------------------------------------- 1.10s

..

You will now have a backup of the Letsencrypt certificates for both
``yellow`` and ``purple``:

.. code-block:: none

    $ tree /opt/dims/backups/
    /opt/dims/backups/
    ├── purple.devops.develop
    │   ├── letsencrypt_2017-08-12T22:55:32PDT.tgz
    │   └── postgresql_2017-08-12T20:50:33PDT.pgdmp.bz2
    └── yellow.devops.develop
        ├── letsencrypt_2017-08-12T22:55:32PDT.tgz
        └── postgresql_2017-08-12T20:50:33PDT.pgdmp.bz2

    2 directories, 4 files

..

.. _restoring_from_backup:

Restoring from a Backup
-----------------------

To restore the Trident PostgreSQL backups, use the playbook
``playbooks/postgresql_restore.yml``.  This playbook is similar to the backup
playbook, however it has no default (you must specify the host or group you
want to restore explicitly).

.. literalinclude:: ../../playbooks/postgresql_restore.yml

To invoke this task file from within the ``trident-core`` role, which will
pre-populate the Trident PostgreSQL database from a backup rather than
running ``tsetup``, set the variable ``postgresql_backup_restorefrom``
to point to a specific backup file, or to ``latest`` to have the most recent
backup be applied.

There is no restore playbook for Letsencrypt certificates, however if you
define the variable ``certbot_backup_restorefrom`` to a specific backup
file path, or to ``latest``, it will be restored when the ``nginx``
role is next applied.

.. _scheduled_backups:

Scheduled Backups
-----------------

The last section showed how to manually trigger backups of Trident's
PostgreSQL database or Letsencrypt certificates for NGINX, using
playbooks.

These tasks can be saved in ``crontab`` files to schedule backups for
whatever frequency is desired.  This is not automated at this point
in time.

.. TODO(dittrich): Add example of setting crontab entry using Ansible

.. _other_backups:

Other System Backups
--------------------

All other backup operations will need to be performed manually, or
scheduled using ``crontab`` as discussed in the last section.

.. note::

   If you do create a ``crontab`` entry to perform backups, note the size
   of the backups and prepare to also prune older backups so as to not
   fill your hard drive.  This would be a nice feature to add when
   resources allow it.

..

