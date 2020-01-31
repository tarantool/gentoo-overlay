# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils

DESCRIPTION="Apache Avro schema tools for Tarantool"
HOMEPAGE="https://github.com/tarantool/avro-schema/"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/tarantool/avro-schema"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/tarantool/avro-schema/archive/${PV}.tar.gz -> ${PF}.tar.gz"
fi
RESTRICT="mirror"

LICENSE=""
SLOT="0"
IUSE=""

DEPEND="dev-db/tarantool"
RDEPEND="${DEPEND}"
