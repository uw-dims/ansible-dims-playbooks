.. _upgrading:

Upgrading and Updating Components
=================================

This chapter covers upgrading operating system packages, updating the
``ansible-dims-playbooks`` repo and related private customization repository,
and generally keeping system components up to date.

.. _updatingpycharm:

Updating PyCharm Community Edition
----------------------------------

Now that we have seen an example of setting variables at the host level
that override group variables, and validating the values of those variables
at run time, we will see how an example of upgrading the application.

PyCharm keeps all of its state, including settings, breakpoints, indexes, in internal
data stores in a directory specific to the version of PyCharm being used.  For example,
PyCharm 2016.2.3 files are kept in ``$HOME/.PyCharm2016.2``. When updating to the
release ``2016.3.1``, the location changes to ``$HOME/.PyCharmCE2016.3``. You need
to run PyCharm ``2016.2.3`` to export your settings, then run the new PyCharm
``2016.3.1`` version to import them.

To export settings, run PyCharm ``2016.2.3`` and select **File>Export
Settings...**. A dialog will pop up that allows you to select what to export and
where to export it. You can use the defaults (pay attention to where the exported
setting file is located, since you need to select it in the next step.) Select
**Ok** to complete the export. See Figure :ref:`exportsettings`.

.. _exportsettings:

.. figure:: images/pycharm-export-settings.png
   :alt: Exporting Settings from PyCharm 2016.2.3
   :width: 60%
   :align: center

   Exporting Settings from PyCharm 2016.2.3

..

PyCharm is installed using Ansible. The normal workflow for updating a component
like PyCharm is to test the new version to ensure it works properly, then update
the variables for PyCharm in the Ansible ``inventory`` before exporting your old
settings and then running the ``pycharm`` role for your development system.

.. TODO(dittrich): Add a cross-reference to running the playbook
.. todo::

    Add a cross-reference to running the playbook.

..

After PyCharm has been updated, select **File>Import Settings...** and select
the ``.jar`` file that was created in the previous step and then select **Ok**.
Again, the defaults can be used for selecting the elements to import.
See Figure :ref:`importsettings`.

.. _importsettings:

.. figure:: images/pycharm-import-settings.png
   :alt: Importing Settings from PyCharm 2016.3.1
   :width: 60%
   :align: center

   Importing Settings to PyCharm 2016.3.1

..

Once you have completed this process and are successfully using version ``2016.3.1``,
you can delete the old directory.

.. code-block:: none

   $ rm -rf ~/.PyCharm2016.2

..

Identifying When Rebooting is Needed
------------------------------------

A ``bats`` system test exists to check to see if any packages were installed that
require a reboot.  This test is templated to tailor it for supported operating
systems.  Use the ``test.runner`` script to execute just the ``reboot`` test:

.. code-block:: none

    $ test.runner --match reboot
    [+] Running test system/reboot
     ✗ [S][EV] System does not require a reboot (Ubuntu)
       (in test file system/reboot.bats, line 8)
         `@test "[S][EV] System does not require a reboot (Ubuntu)" {' failed
       linux-image-4.4.0-87-generic
       linux-base
       linux-base

    1 test, 1 failure

..

.. todo::

   Show how to use ad-hoc mode to run this test on all systems at once...

..

