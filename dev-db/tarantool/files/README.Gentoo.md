General
=======

Package provides some additional options in config-file:

* opt file_descriptors = INTVALUE

  Init script will do 'ulimit -n INTVALUE' command before starting tarantool.

* opt save_snapshots = COUNT

  Count of snapshots to save (default = 10). COUNT=0 disables removing
  old snapshots.

* opt snapshot_period = HOURS

  Period between two snapshot (default 24).

There is script tarantool_snapshot_rotate (1) that is started every hour
using cron.hourly. This script is only installed if "walrotate" USE flag is set.

Multiple Instances HOWTO
========================

To create multiple instances of the server please do the next steps:

1. Create a symlink for init script

        ln -s /etc/init.d/tarantool /etc/init.d/tarantool.my

2. Copy the configuration file

        cp /etc/tarantool/tarantool.cfg /etc/tarantool/my.cfg

3. Update `*_port` parameters in my.cfg and replace `tarantool.log` and `tarantool.pid`
with `my.log` and `my.pid` correspondingly in my.cfg

5. Init data directory (optional, automatically performed on the first startup)

        /etc/init.d/tarantool.my initstorage

Now you can start the second Tarantool instance called 'my' by regular
/etc/init.d/tarantool.my init script.
