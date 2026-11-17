# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module bash-completion-r1

DESCRIPTION="Command-line utility to manage Tarantool applications"
HOMEPAGE="https://github.com/tarantool/tt"

# The project is licensed under BSD-2, other licenses are from its
# dependencies.
LICENSE="BSD-2 MIT Apache-2.0 BSD MPL-2.0"
SLOT="0"

# Minimal Go version is taken from the `go` directive in go.mod of a
# release.
if [[ ${PV} == *9999* ]]; then
	GO_MIN="1.26.10"
elif ver_test ${PV} -ge 2.15.0; then
	GO_MIN="1.25.7"
elif ver_test ${PV} -ge 2.11.0; then
	GO_MIN="1.23.8"
elif ver_test ${PV} -ge 2.5.0; then
	GO_MIN="1.21"
else
	GO_MIN="1.20"
fi
BDEPEND=">=dev-lang/go-${GO_MIN} dev-build/mage"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGO_PN=github.com/tarantool/${PN}
	EGIT_REPO_URI="https://${EGO_PN}.git"

	src_unpack() {
		git-r3_src_unpack
		mage -d ${PN}-9999 PatchCC GenerateGoCode
		go-module_live_vendor
	}

	src_prepare() {
		eapply_user
		eapply "${FILESDIR}"/tt-build-vendor.patch
	}
else
	SRC_URI="https://github.com/tarantool/tt/releases/download/v${PV}/${P}-complete.tar.gz"
	SRC_URI+=" https://github.com/tarantool/tt/releases/download/v${PV}/${P}-deps.tar.xz"
	KEYWORDS="~amd64"
	RESTRICT="mirror"
fi

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

	insinto /etc/tarantool
	newins package/tt.yaml.default tt.yaml
}
