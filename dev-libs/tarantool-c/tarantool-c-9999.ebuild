# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake

DESCRIPTION=""
HOMEPAGE="https://github.com/tarantool/tarantool-c"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/tarantool/tarantool-c"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/tarantool/tarantool-c/archive/${PV}.tar.gz -> ${PF}.tar.gz"
fi
RESTRICT="mirror"

LICENSE="BSD-2"
SLOT="0"
IUSE="+system-msgpuck debug"

# A static libmsgpuck.a is linked into libtarantool.{so,a}, so
# msgpuck is only build time dependency.
RDEPEND=""
DEPEND="
	system-msgpuck? ( dev-libs/msgpuck )
"

src_configure() {
	if use debug; then
		export CMAKE_BUILD_TYPE=Debug
	else
		export CMAKE_BUILD_TYPE=Release
	fi

	local mycmakeargs=(
		-DENABLE_BUNDLED_MSGPUCK=$(usex system-msgpuck OFF ON)
	)
	cmake_src_configure
}
