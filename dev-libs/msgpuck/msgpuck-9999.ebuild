# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils

DESCRIPTION="Lightweight MessagePack library"
HOMEPAGE="https://github.com/tarantool/msgpuck"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/tarantool/msgpuck"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/tarantool/msgpuck/archive/${PV}.tar.gz -> ${PF}.tar.gz"
fi
RESTRICT="mirror"

LICENSE="BSD-2"
SLOT="2"
IUSE=""
