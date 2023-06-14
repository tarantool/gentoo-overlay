# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module bash-completion-r1

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
	mkdir -pv completions || die
	./tt completion bash > completions/${PN} || die
	./tt completion zsh > completions/_${PN} || die
}

src_test() {
	ego test ./...
}

src_install() {
	dobin ${PN}

	dobashcomp completions/${PN}
	insinto /usr/share/zsh/site-functions
	doins completions/_${PN}
}
