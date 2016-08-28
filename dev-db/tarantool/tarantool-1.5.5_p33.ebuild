# Copyright 2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

CMAKE_MIN_VERSION=2.6
# Required for USE="doc"
CMAKE_IN_SOURCE_BUILD=1

inherit cmake-utils eutils user

UPSTREAM_VERSION=1.5.5-33-g38b2398
SRC_URI="http://tarantool.org/dist/stable/tarantool-${UPSTREAM_VERSION}-src.tar.gz"
S=${WORKDIR}/tarantool-${UPSTREAM_VERSION}-src

DESCRIPTION="Tarantool - an efficient, extensible in-memory data store."
HOMEPAGE="http://tarantool.org"
IUSE="debug +client +server static +backtrace +logrotate +walrotate sse2 avx doc gcov gprof mysql postgres test"

SLOT="0"
LICENSE="BSD-2"
KEYWORDS="~x86 ~amd64"

RDEPEND="
	dev-lang/perl
	sys-libs/libunwind
	client? ( sys-libs/readline sys-libs/ncurses )
	mysql? ( virtual/mysql )
	postgres? ( dev-db/postgresql-base )
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
	|| ( client server )
"

TARANTOOL_HOME="/var/lib/tarantool"
TARANTOOL_USER=tarantool
TARANTOOL_GROUP=tarantool

src_prepare() {
	epatch "${FILESDIR}/tarantool-1.5-script-paths.patch"
	epatch "${FILESDIR}/tarantool-1.5-tests.patch"

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
		$(cmake-utils_use_enable static STATIC)
		$(cmake-utils_use_enable backtrace BACKTRACE)
		$(cmake-utils_use_enable sse2 SSE2)
		$(cmake-utils_use_enable avx AVX)
		$(cmake-utils_use_enable doc DOC)
		$(cmake-utils_use_enable gcov GCOV)
		$(cmake-utils_use_enable client CLIENT)
		$(cmake-utils_use_with postgres POSTGRESQL)
		$(cmake-utils_use_with mysql MYSQL)
		-DCMAKE_SKIP_RPATH=YES
	)
	cmake-utils_src_configure
}


src_compile() {
	if has test $FEATURES; then
		# Compile server, client and unit tests if USE=test is set
		cmake-utils_src_compile
	else
		if use client; then
			# Compile client libraries and console client
			cmake-utils_src_compile -C connector all
			cmake-utils_src_compile -C client all
		fi
		if use server; then
			# Compile server
			cmake-utils_src_compile tarantool_box
		fi
		# Compile all man pages
		cmake-utils_src_compile man
	fi
	if use doc; then
		# Compile docbook documentation (haven't done by 'make all')
		cmake-utils_src_compile doc-autogen
	fi
}

src_test() {
	if ! cmake-utils_src_compile test; then
		hasq test $FEATURES && die "Make test failed. See above for details."
		hasq test $FEATURES || eerror "Make test failed. See above for details."
	fi
}

src_install() {
	# Basic docs
	dodoc README.md || die "dodoc failed"
	dodoc AUTHORS || die "dodoc failed"
	dodoc TODO || die "dodoc failed"

	# User guide
	if use doc; then
		dodoc doc/box-protocol.txt || die "dodoc failed"
		dohtml ${BUILD_DIR}/doc/www-data/tarantool_user_guide.html || die "dohtml failed"
	fi
	
	if use client; then
		# Client libraries
		cmake-utils_src_install -C connector
		cmake-utils_src_install -C client

		# Client documentation
		if use doc; then
			dodoc doc/sql.txt || die "dodoc failed"
		fi
	fi

	if ! use server; then
		return 0
	fi

	# Server binary and plugins
	cmake-utils_src_install -C src

	# Server man pages
	doman ${BUILD_DIR}/doc/man/tarantool_box.1 || die "doman failed"

	# Server documentation
	dodoc ${FILESDIR}/README.Gentoo.md || die "dodoc failed"
	newdoc ${FILESDIR}/tarantool.cfg example.cfg || die "dodoc failed"

	# Configuration
	insinto /etc/tarantool
	doins ${FILESDIR}/tarantool.cfg || die "doins failed"

	# Data directory
	keepdir /var/lib/tarantool

	# Lua scrips
	keepdir /usr/share/tarantool

	# Init script
	newinitd "${FILESDIR}"/tarantool.initd tarantool

	# Logger
	exeinto /usr/$(get_libdir)/tarantool/
	newexe extra/logger.pl tarantool_logger \
			|| die "newexe failed"

	# Logrotate scripts
	if use logrotate; then
		insinto /etc/logrotate.d
		newins "${FILESDIR}"/tarantool.logrotate tarantool \
				|| die "newins failed"
		exeinto /usr/$(get_libdir)/tarantool/
		doexe debian/scripts/tarantool_logrotate \
				|| die "newexe failed"
	fi

	# WAL-rotate scripts
	if use walrotate; then
		exeinto /etc/cron.daily
		doexe "${FILESDIR}"/tarantool.cron || die "doexe failed"
		dobin debian/scripts/tarantool_snapshot_rotate || die "doexe failed"
	fi
}

pkg_postinst() {
	einfo
	einfo "It is possible to run multiple servers using init.d scrips."
	einfo "Please check README.Gentoo.md file"
	einfo "in /usr/share/doc/${PF} folder for additional information."
	einfo
}
