# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="A user for dev-db/tarantool"
ACCT_USER_ID="3301"
ACCT_USER_GROUPS=( tarantool )
ACCT_USER_HOME="/var/lib/tarantool"

acct-user_add_deps
