# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

case $PV in *9999*) VCS_ECLASS="git-r3" ;; *) VCS_ECLASS="" ;; esac

inherit ${VCS_ECLASS}

DESCRIPTION="Lua bindings for Google Performance Tools CPU Profiler"
HOMEPAGE="https://github.com/tarantool/gperftools"

if [ -n "${VCS_ECLASS}" ]; then
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/tarantool/gperftools"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/tarantool/gperftools/archive/${PV}.tar.gz -> tarantool_${PF}.tar.gz"
fi
RESTRICT="mirror"

LICENSE="BSD-2"
SLOT="0"
IUSE=""

DEPEND="dev-db/tarantool"
RDEPEND="
	${DEPEND}
	dev-util/google-perftools
"

src_install() {
	dodir /usr/share/tarantool/gperftools
	insinto /usr/share/tarantool/gperftools
	doins gperftools/cpu.lua
	doins gperftools/init.lua
}
