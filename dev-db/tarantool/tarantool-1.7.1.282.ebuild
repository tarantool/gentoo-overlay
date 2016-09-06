# Copyright 2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

CMAKE_MIN_VERSION=2.6

inherit cmake-utils eutils user versionator

MAJORV=$(get_version_component_range 1-2)
SRC_URI="http://download.tarantool.org/tarantool/${MAJORV}/src/${P}.tar.gz"

DESCRIPTION="Tarantool - an efficient, extensible in-memory data store."
HOMEPAGE="http://tarantool.org"
IUSE="debug +backtrace systemd gcov gprof test cpu_flags_x86_sse2 cpu_flags_x86_avx"

SLOT="0/${MAJORV}"
LICENSE="BSD-2"
KEYWORDS="~x86 ~amd64"

RDEPEND="
	dev-lang/perl
	sys-libs/libunwind
	sys-libs/readline:0
	sys-libs/ncurses:0
	dev-libs/libyaml
	app-arch/lz4
"

DEPEND="
	${RDEPEND}
	|| ( >=sys-devel/gcc-4.5[cxx]  >=sys-devel/clang-3.2 )
	test? ( dev-python/python-daemon dev-python/pyyaml dev-python/pexpect )
"

REQUIRED_USE="
	cpu_flags_x86_avx? ( cpu_flags_x86_sse2 )
"

TARANTOOL_HOME="/var/lib/tarantool"
TARANTOOL_USER=tarantool
TARANTOOL_GROUP=tarantool

PATCHES="${FILESDIR}/tarantool-${MAJORV}-clean.patch"

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
		-DCMAKE_INSTALL_SYSCONFDIR=/etc
		-DENABLE_BUNDLED_LIBYAML=OFF
		-DENABLE_BUNDLED_LZ4=OFF
	)
	cmake-utils_src_configure
}

#src_test() {
#	if ! cmake-utils_src_compile test; then
#		hasq test $FEATURES && die "Make test failed. See above for details."
#		hasq test $FEATURES || eerror "Make test failed. See above for details."
#	fi
#}

src_install() {
	# User guide
	dodoc README.md
	dodoc AUTHORS
	dodoc TODO

	# Server documentation
	dodoc "${FILESDIR}"/README.Gentoo.md

	# Server binary and plugins
	cmake-utils_src_install

	# Data directory
	keepdir /var/lib/tarantool

	# Lua scrips
	keepdir /usr/share/tarantool

	# Init script
	newinitd "${FILESDIR}/tarantool.initd" tarantool
}

pkg_postinst() {
	einfo
	einfo "It is possible to run multiple servers using init.d scrips."
	einfo "Please check README.Gentoo.md file"
	einfo "in /usr/share/doc/${PF} folder for additional information."
	einfo
}
