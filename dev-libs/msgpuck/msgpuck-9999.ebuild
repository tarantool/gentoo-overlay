# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

case $PV in *9999*) VCS_ECLASS="git-r3" ;; *) VCS_ECLASS="" ;; esac

inherit cmake-utils ${VCS_ECLASS}

DESCRIPTION="A simple and efficient MsgPack binary serialization library in a self-contained header file"
HOMEPAGE="https://github.com/rtsisyk/msgpuck"

if [ -n "${VCS_ECLASS}" ]; then
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/tarantool/msgpuck"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/rtsisyk/msgpuck/archive/${PV}.tar.gz -> ${PF}.tar.gz"
fi
RESTRICT="mirror"

LICENSE="BSD-2"
SLOT="2"
IUSE=""
