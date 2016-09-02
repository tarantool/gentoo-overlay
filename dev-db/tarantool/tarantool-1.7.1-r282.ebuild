# Copyright 2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

CMAKE_MIN_VERSION=2.6
# Required for USE="doc"
CMAKE_IN_SOURCE_BUILD=1

inherit cmake-utils eutils user versionator

MAJORV=$(get_version_component_range 1-2)
SRC_URI="http://download.tarantool.org/tarantool/${MAJORV}/src/tarantool-${PV}.${PR#r}.tar.gz"
S="${WORKDIR}/tarantool-${PV}.${PR#r}"

DESCRIPTION="Tarantool - an efficient, extensible in-memory data store."
HOMEPAGE="http://tarantool.org"
IUSE="debug static +backtrace +logrotate sse2 avx doc gcov gprof test"

SLOT="0"
LICENSE="BSD-2"
KEYWORDS="~x86 ~amd64"

RDEPEND="
	dev-lang/perl
	sys-libs/libunwind
	sys-libs/readline
	sys-libs/ncurses
"

DEPEND="
	${RDEPEND}
	|| ( >=sys-devel/gcc-4.5[cxx]  >=sys-devel/clang-3.2 )
	test? ( dev-python/python-daemon dev-python/pyyaml dev-python/pexpect )
	doc? ( app-text/jing www-client/lynx app-text/docbook-xml-dtd
	       app-text/docbook-xsl-ns-stylesheets app-text/docbook-xsl-stylesheets )
"

REQUIRED_USE="
	avx? ( sse2 )
"

TARANTOOL_HOME="/var/lib/tarantool"
TARANTOOL_USER=tarantool
TARANTOOL_GROUP=tarantool

src_prepare() {
	epatch "${FILESDIR}/tarantool-${MAJORV}-paths.patch"

	eapply_user
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
		-DENABLE_STATIC="$(usex static)"
		-DENABLE_BACKTRACE="$(usex backtrace)"
		-DENABLE_SSE2="$(usex sse2)"
		-DENABLE_AVX="$(usex avx)"
		-DENABLE_DOC="$(usex doc)"
		-DENABLE_GCOV="$(usex gcov)"
		-DCMAKE_SKIP_RPATH=YES
		-DENABLE_DIST=ON
	)
	cmake-utils_src_configure
}


src_compile() {
	cmake-utils_src_compile
}

src_test() {
	if ! cmake-utils_src_compile test; then
		hasq test $FEATURES && die "Make test failed. See above for details."
		hasq test $FEATURES || eerror "Make test failed. See above for details."
	fi
}

src_install() {
	# Basic docs
	dodoc README.md
	dodoc AUTHORS
	dodoc TODO

	# User guide
	if use doc; then
		dodoc doc/box-protocol.txt
		dohtml ${BUILD_DIR}/doc/www-data/tarantool_user_guide.html
	fi

	use doc && dodoc doc/sql.txt


	# Server binary and plugins
	cmake-utils_src_install

	# Server man pages
#	doman ${BUILD_DIR}/doc/man/tarantool.1

	# Server documentation
	dodoc ${FILESDIR}/README.Gentoo.md

	# Data directory
	keepdir /var/lib/tarantool

	# Lua scrips
	keepdir /usr/share/tarantool

	# Init script
	newinitd extra/dist/tarantoolctl tarantool
}

pkg_postinst() {
	einfo
	einfo "It is possible to run multiple servers using init.d scrips."
	einfo "Please check README.Gentoo.md file"
	einfo "in /usr/share/doc/${PF} folder for additional information."
	einfo
}
