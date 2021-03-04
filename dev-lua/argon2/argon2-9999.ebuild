# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CMAKE_MAKEFILE_GENERATOR="emake"
inherit cmake-utils

DESCRIPTION="Tarantool C binding for the Argon2 password hashing algorithm"
HOMEPAGE="https://github.com/tarantool/argon2/"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/tarantool/argon2"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/tarantool/argon2/archive/${PV}.tar.gz -> ${PF}.tar.gz"
fi
RESTRICT="mirror"

LICENSE=""
SLOT="0"
IUSE=""

DEPEND="dev-db/tarantool"
RDEPEND="${DEPEND}"
