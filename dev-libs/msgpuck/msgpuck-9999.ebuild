# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils

DESCRIPTION="A simple and efficient MsgPack binary serialization library in a self-contained header file"
HOMEPAGE="https://github.com/rtsisyk/msgpuck"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
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
