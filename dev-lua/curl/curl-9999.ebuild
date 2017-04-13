# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

case $PV in *9999*) VCS_ECLASS="git-r3" ;; *) VCS_ECLASS="" ;; esac

inherit cmake-utils ${VCS_ECLASS}

DESCRIPTION="Curl bindings for Tarantool"
HOMEPAGE="https://github.com/tarantool/curl/"

if [ -n "${VCS_ECLASS}" ]; then
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/tarantool/curl"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/tarantool/curl/archive/${PV}.tar.gz -> ${PF}.tar.gz"
fi
RESTRICT="mirror"

LICENSE=""
SLOT="0"
IUSE=""

DEPEND="
	dev-db/tarantool
	dev-libs/libev
	net-misc/curl[ssl]
"
RDEPEND="${DEPEND}"
