Multiple Instances HOWTO
========================

To create multiple instances of the server please do the next steps:

1. Create a symlink for init script

        ln -s /etc/init.d/tarantool /etc/init.d/tarantool.my

2. Create configuration file tarantool.my in

	/etc/tarantool/instances.enabled

Now you can start the second Tarantool instance called 'tarantool.my' by regular
/etc/init.d/tarantool.my init script.
