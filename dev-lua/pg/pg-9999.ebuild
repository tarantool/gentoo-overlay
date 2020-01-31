# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake-utils

DESCRIPTION="PostgreSQL connector for Tarantool"
HOMEPAGE="https://github.com/tarantool/pg"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/tarantool/pg"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/tarantool/pg/archive/${PV}.tar.gz -> ${PF}.tar.gz"
fi
RESTRICT="mirror"

LICENSE=""
SLOT="0"
IUSE=""

DEPEND="
	dev-db/tarantool
	dev-db/postgresql
"
RDEPEND="${DEPEND}"
