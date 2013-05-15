# Copyright 2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2

CMAKE_MIN_VERSION=2.6
# See https://bugs.launchpad.net/tarantool/+bug/1180494
CMAKE_IN_SOURCE_BUILD=1

inherit cmake-utils eutils git-2

EGIT_REPO_URI="git://github.com/mailru/tarantool.git"

case ${PV} in
	1.4.9999)
		# Stable branch
		EGIT_BRANCH="stable";;
	default)
		# Master branch
		EGIT_BRANCH="master";;
esac

DESCRIPTION="Tarantool - an efficient, extensible in-memory data store."
HOMEPAGE="http://tarantool.org"
IUSE="debug static +backtrace +libobjc-bundled +luajit-bundled +logrotate +walrotate sse2 avx doc gcov gprof"

SLOT="0"
LICENSE="BSD-2"
KEYWORDS="~x86 ~amd64"

RDEPEND="
	dev-lang/perl
	!luajit-bundled? ( >=dev-lang/luajit-2.0 )
	luajit-bundled? ( sys-libs/libunwind )
"

DEPEND="
	${RDEPEND}
	|| ( >=sys-devel/gcc-4.4[cxx,objc,objc+]  >=sys-devel/clang-3.1 )
	test? ( dev-python/python-daemon dev-python/pyyaml dev-python/pexpect )
	doc? ( app-text/jing www-client/lynx app-text/docbook-xml-dtd
	       app-text/docbook-xsl-ns-stylesheets app-text/docbook-xsl-stylesheets )
"

#REQUIRED_USE="avx? ( sse2 )"

TARANTOOL_HOME="/var/lib/tarantool"
TARANTOOL_USER=tarantool
TARANTOOL_GROUP=tarantool

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
		$(cmake-utils_use_enable static STATIC)
		$(cmake-utils_use_enable backtrace BACKTRACE)
		$(cmake-utils_use_enable libobjc-bundled BUNDLED_LIBOBJC)
		$(cmake-utils_use_enable luajit-bundled BUNDLED_LUAJIT)
		$(cmake-utils_use_enable sse2 SSE2)
		$(cmake-utils_use_enable avx AVX)
		$(cmake-utils_use_enable doc DOC)
		$(cmake-utils_use_enable gcov GCOV)
		-DENABLE_CLIENT=OFF
	)
	cmake-utils_src_configure
}


src_compile() {
	cmake-utils_src_compile tarantool_box man
	if use doc; then
		cmake-utils_src_compile doc-autogen
	fi
	# TODO: add a special target for building tests into cmake
}

src_test() {
	cmake-utils_src_compile test
}

src_install() {
	# Binary intsels
	dobin ${BUILD_DIR}/src/box/tarantool_box || die "doexe failed"

	# Logger
	dobin "${FILESDIR}"/tarantool_logger

	# Man page
	doman ${BUILD_DIR}/doc/man/tarantool_box.1 || die "doman failed"

	# Basic docs
	dodoc README.md || die "dodoc failed"
	dodoc AUTHORS || die "dodoc failed"
	dodoc TODO || die "dodoc failed"
	dodoc ${FILESDIR}/README.MultiInstance.md || die "dodoc failed"

	# User guide
	if use doc; then
		dodoc doc/box-protocol.txt || die "dodoc failed"
		dodoc doc/sql.txt || die "dodoc failed"
		dohtml ${BUILD_DIR}/doc/www-data/tarantool_user_guide.html || die "dohtml failed"
	fi

	# Configuration
	insinto /etc/tarantool
	doins ${FILESDIR}/tarantool.cfg || die "doins failed"

	# Initial database
	keepdir /var/lib/tarantool
	insinto /var/lib/tarantool/tarantool
	doins test/box/00000000000000000001.snap || die "doins failed"
	fowners -R ${TARANTOOL_USER}:${TARANTOOL_GROUP} /var/lib/tarantool

	# Directory for pid files
	keepdir /run/tarantool
	fowners ${TARANTOOL_USER}:${TARANTOOL_GROUP} /run/tarantool


	# Lua scrips
	keepdir /usr/share/tarantool/lua

	# Init script
	newinitd "${FILESDIR}"/tarantool.initd tarantool

	# Logrotate scripts
	if use logrotate; then
		insinto /etc/logrotate.d
		newins "${FILESDIR}"/tarantool.logrotate tarantool
		dobin "${FILESDIR}/tarantool_logrotate"
	fi

	# WAL-rotate scripts
	if use walrotate; then
		exeinto /etc/cron.daily
		doexe "${FILESDIR}"/tarantool.cron
		dobin "${FILESDIR}/tarantool_snapshot_rotate"
	fi
}

pkg_postinst() {
	einfo
	einfo "It is possible to run multiple servers using init.d scrips."
	einfo "Please check README.MultiInstance.md file"
	einfo "in /usr/share/doc/${PF} folder for additional information."
	einfo
}
