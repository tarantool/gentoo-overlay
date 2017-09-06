# Copyright 2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

CMAKE_MIN_VERSION=2.6

case $PV in *9999*) VCS_ECLASS="git-r3" ;; *) VCS_ECLASS="" ;; esac

inherit cmake-utils eutils user versionator ${VCS_ECLASS}

MAJORV=$(get_version_component_range 1-2)

DESCRIPTION="Tarantool - an efficient, extensible in-memory data store."
HOMEPAGE="http://tarantool.org"
IUSE="debug +backtrace systemd gcov gprof test cpu_flags_x86_sse2 cpu_flags_x86_avx"

if [ -n "${VCS_ECLASS}" ]; then
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/tarantool/$PN"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="http://download.tarantool.org/tarantool/${MAJORV}/src/${P}.tar.gz"
fi
RESTRICT="mirror"

SLOT="0/${MAJORV}"
LICENSE="BSD-2"
KEYWORDS="~x86 ~amd64 ~x64-macos"

RDEPEND="
	!x64-macos? ( sys-libs/libunwind )
	sys-libs/readline:0
	sys-libs/ncurses:0
	dev-libs/libyaml
	app-arch/lz4
"

DEPEND="
	${RDEPEND}
	dev-lang/perl
	|| ( >=sys-devel/gcc-4.5[cxx]  >=sys-devel/clang-3.2 )
	test? ( dev-python/python-daemon dev-python/pyyaml dev-python/pexpect )
"

REQUIRED_USE="
	cpu_flags_x86_avx? ( cpu_flags_x86_sse2 )
	x64-macos? ( !backtrace )
"

TARANTOOL_HOME="/var/lib/tarantool"
TARANTOOL_USER=tarantool
TARANTOOL_GROUP=tarantool

#PATCHES="${FILESDIR}/tarantool-${MAJORV}-clean.patch"

pkg_pretend() {
	# clang is not sloted at this moment, we are ok with any installed one.
	if [[ $(tc-getCC) == clang ]]; then
		:
	elif [[ $(gcc-major-version) -lt 4 ]] || {
		[[ $(gcc-major-version) -eq 4 && $(gcc-minor-version) -lt 5 ]]; } then
		 eerror "Compilation with gcc older than 4.5 is not supported"
		 die "Too old gcc found."
	fi
}

pkg_setup() {
	ebegin "Creating tarantool user and group"
	enewgroup ${TARANTOOL_GROUP}
	enewuser ${TARANTOOL_USER} -1 -1 "${TARANTOOL_HOME}" ${TARANTOOL_GROUP}
	eend $?
}

src_configure() {
	if use debug; then
		export CMAKE_BUILD_TYPE=Debug
	else
		export CMAKE_BUILD_TYPE=RelWithDebugInfo
	fi

	local mycmakeargs=(
		-DENABLE_BACKTRACE="$(usex backtrace)"
		-DENABLE_SSE2="$(usex cpu_flags_x86_sse2)"
		-DENABLE_AVX="$(usex cpu_flags_x86_avx)"
		-DENABLE_GCOV="$(usex gcov)"
		-DWITH_SYSTEMD="$(usex systemd)"
		-DCMAKE_SKIP_RPATH=ON
		-DENABLE_DIST=ON
		-DWITH_SYSVINIT=OFF
		-DCMAKE_INSTALL_SYSCONFDIR="$(readlink -f ${EROOT}/etc)"
		-DENABLE_BUNDLED_LIBYAML=OFF
		-DENABLE_BUNDLED_LZ4=OFF
	)
	cmake-utils_src_configure
}

src_install() {
	# User guide
	dodoc README.md
	dodoc AUTHORS
	dodoc TODO

	# Server binary and plugins
	cmake-utils_src_install

	# Data directory
	keepdir /var/lib/tarantool
	fowners "${TARANTOOL_USER}:${TARANTOOL_GROUP}" /var/log/tarantool

	# Lua scrips
	keepdir /usr/share/tarantool

	# Init script
	newinitd "${FILESDIR}/tarantool.initd" tarantool
}

pkg_postinst() {
	elog
	elog "It is possible to run multiple servers using init.d scrips. Consider"
	elog "the following example:"
	elog
	elog "Create a service:"
	elog "$ vim /etc/tarantool/instances.available/tarantool-myservice.lua"
	elog
	elog "OpenRC:"
	elog "$ ln -s /etc/init.d/tarantool /etc/init.d/tarantool.myservice"
	elog "$ service tarantool-myservice start"
	elog
	elog "Systemd:"
	elog "$ service tarantool@p2phub start"
	elog
}
