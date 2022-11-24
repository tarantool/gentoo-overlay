# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module

DESCRIPTION="Command-line utility to manage Tarantool applications"
HOMEPAGE="https://github.com/tarantool/tt"
SRC_URI="https://github.com/tarantool/tt/releases/download/v${PV}/${P}-complete.tar.gz"
SRC_URI+=" https://github.com/tarantool/tt/releases/download/v${PV}/${P}-deps.tar.xz"

# The project is licensed under BSD-2, other licenses are from its
# dependencies.
LICENSE="BSD-2 MIT Apache-2.0 BSD MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
BDEPEND=">=dev-lang/go-1.18 dev-util/mage"

src_compile() {
	mage build
}

src_test() {
	ego test ./...
}

src_install() {
	dobin ${PN}
}
