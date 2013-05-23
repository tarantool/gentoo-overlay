Gentoo Multiple Instances HOWTO
===============================

To create multiple instances of the server please do the next steps:

1. Create a symlink for init script

        ln -s /etc/init.d/tarantool /etc/init.d/tarantool.my

2. Copy the configuration file

        cp /etc/tarantool/tarantool.cfg /etc/tarantool/my.cfg

3. Update `*_port` parameters in my.cfg and replace `tarantool.log` and `tarantool.pid`
with `my.log` and `my.pid` correspondingly in my.cfg

5. Init data directory

        mkdir /var/lib/tarantool/my
        cd /var/lib/tarantool/my
        tarantool_box --init-storage
        chown -R tarantool:tarantool /var/lib/tarantool/my

Now you can start the second Tarantool instance called 'my' by regular
/etc/init.d/tarantool.my init script.
