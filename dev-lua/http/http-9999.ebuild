# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake

DESCRIPTION="HTTP server for Tarantool"
HOMEPAGE="https://github.com/tarantool/http/"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/tarantool/http"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/tarantool/http/archive/${PV}.tar.gz -> ${PF}.tar.gz"
fi
RESTRICT="mirror"

LICENSE=""
SLOT="0"
IUSE=""

DEPEND="
	dev-db/tarantool
	dev-lua/checks
"
RDEPEND="${DEPEND}"
