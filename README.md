Tarantool Gentoo Overlay
========================

Tarantool, http://tarantool.org/

Tarantool is an efficient NoSQL database and a Lua application server.

Using repository with newer portage
-----------------------------------

A package manager with git repository support can be used for sync.
Portage version 2.2.16 and later supports git sync.

The `repos.conf` entry for repository sync may look like the following:

    [tarantool]
    location = /usr/local/portage/tarantool
    sync-type = git
    sync-uri = https://github.com/tarantool/gentoo-overlay.git
    auto-sync = true

Please note that if you use existing repository location, you *need to
remove the existing repository first*.

Using repository with layman
----------------------------

    layman -S
    layman -a tarantool
    emerge --autounmask-write tarantool
    etc-update
    emerge -av tarantool
