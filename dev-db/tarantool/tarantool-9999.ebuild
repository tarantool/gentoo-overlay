# Copyright 2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=8

inherit cmake tmpfiles

MAJORV=$(ver_cut 1)
MINORV=$(ver_cut 2)

# The Ninja makefile generator has been supported since version 2.10.1 (yanked).
if ver_test ${PV} -lt 2.10.2; then
	CMAKE_MAKEFILE_GENERATOR=emake
fi

# Version enumeration policy and source tarballs layout were
# changed, handle it.
#
# https://github.com/tarantool/tarantool/discussions/6182
if [ "${PV}" = 9999 ]; then
	inherit git-r3
	KEYWORDS=""
	SERIES="9999"
	EGIT_REPO_URI="https://github.com/tarantool/${PN}"
elif [ "${MAJORV}" = 1 ] || ([ "${MAJORV}" = 2 ] && [ "${MINORV}" -lt 10 ]); then
	# Old release policy.
	KEYWORDS="~amd64 ~x86"
	SERIES="${MAJORV}.${MINORV}"
	SRC_URI="https://download.tarantool.org/tarantool/${SERIES}/src/${P}.tar.gz"
else
	# New release policy.
	KEYWORDS="~amd64 ~x86 ~arm64"
	SERIES="${MAJORV}"
	SRC_URI="https://download.tarantool.org/tarantool/src/${P/_/-}.tar.gz"
	S="${WORKDIR}/${P/_/-}"
fi

DESCRIPTION="Tarantool - an efficient, extensible in-memory data store."
HOMEPAGE="https://tarantool.org"
IUSE="
	+backtrace debug embed-luarocks feedback-daemon gcov gprof
	+system-libcurl +system-libyaml +system-zstd systemd test
	cpu_flags_x86_sse2 cpu_flags_x86_avx
"

RESTRICT="mirror"
SLOT="0/${SERIES}"
LICENSE="BSD-2"

BDEPEND="
	acct-group/tarantool
	acct-user/tarantool
	>=dev-build/cmake-2.6
"

RDEPEND="
	sys-libs/libunwind
	sys-libs/readline:0
	sys-libs/ncurses:0
	system-libcurl? ( >=net-misc/curl-7.65.3 )
	system-libyaml? ( >=dev-libs/libyaml-0.2.2 )
	system-zstd? ( app-arch/zstd )
	dev-libs/icu
"

DEPEND="
	${RDEPEND}
	test? ( dev-python/gevent dev-python/pyyaml )
"

REQUIRED_USE="
	cpu_flags_x86_avx? ( cpu_flags_x86_sse2 )
"

TARANTOOL_RUNDIR="/run/tarantool"
TARANTOOL_USER=tarantool
TARANTOOL_GROUP=tarantool

pkg_pretend() {
	if ! use system-libcurl && ! ( \
			([[ ${PV} =~ ^1.* ]] && ver_test ${PV} -ge 1.10.3.120) || \
			([[ ${PV} =~ ^2.1.* ]] && ver_test ${PV} -ge 2.1.2.155) || \
			([[ ${PV} =~ ^2.2.* ]] && ver_test ${PV} -ge 2.2.1.19) || \
			([[ ${PV} =~ ^2.3.* ]] && ver_test ${PV} -ge 2.3.0.42) || \
			[[ ${PV} == 9999 ]]); then
		eerror "USE flag \"system-libcurl\" is disabled, but ${PF} version"
		eerror "is older then needed for using bundled libcurl."
		die "Cannot enable system libcurl."
	fi
}

src_prepare() {
	# -DENABLE_FEEDBACK_DAEMON=OFF does the job, but it is
	# available only since 2.4.0.231 (see [1]).
	#
	# [1]: https://github.com/tarantool/tarantool/issues/3308
	if ! use feedback-daemon && ! ver_test ${PV} -ge 2.4.0.231 && ( \
			([[ ${PV} =~ ^1.* ]] && ver_test ${PV} -ge 1.10.0.28) || \
			([[ ${PV} =~ ^2.* ]] && ver_test ${PV} -ge 2.0.4.163)); then
		# Revert 2ae373ae741dcf975c5d176316d8290c962446ba.
		#
		# Applying a patch would fail due to differences across
		# versions, so going to the bad (but robust) way.
		local comment='disabled by USE=-feedback-daemon'

		sed -e 's@^\s*lua_source(lua_sources lua/feedback_daemon\.lua)$@# \0 # '"${comment}@" \
			-i src/box/CMakeLists.txt
		[ "$(grep "${comment}" src/box/CMakeLists.txt | wc -l)" = 1 ] || \
			die "sed out feedback-daemon from src/box/CMakeLists.txt"

		sed -e 's@^\s*feedback_daemon_lua\[\],$@// \0 // '"${comment}@" \
			-e 's@^\s*"box/feedback_daemon", feedback_daemon_lua,@// \0 // '"${comment}@" \
			-i src/box/lua/init.c
		[ "$(grep "${comment}" src/box/lua/init.c | wc -l)" = 2 ] || \
			die "sed out feedback-daemon from src/box/lua/init.c"

		# Comment out feedback_* fields in default_cfg,
		# template_cfg, dynamic_cfg tables.
		#
		# feedback_crashinfo appears since 2.7.0.154, but we use
		# -DENABLE_FEEDBACK_DAEMON=OFF CMake flag since 2.4.0.231.
		# Ignore it so.
		sed -e 's@^\s*feedback_enabled *=.*$@-- \0 -- '"${comment}@" \
			-e 's@^\s*feedback_host *=.*$@-- \0 -- '"${comment}@" \
			-e 's@^\s*feedback_interval *=.*$@-- \0 -- '"${comment}@" \
			-i src/box/lua/load_cfg.lua
		[ "$(grep "${comment}" src/box/lua/load_cfg.lua | wc -l)" = 9 ] || \
			die "sed out feedback-daemon from src/box/lua/load_cfg.lua"

		echo 'box.feedback = nil' >> src/box/lua/schema.lua \
			|| die "echo box.feedback"
		rm src/box/lua/feedback_daemon.lua || die "rm feedback_daemon.lua"
	fi

	# Tarantool CMake files do not provide a way to set rundir separately from
	# datadir (/var/lib/tarantool) and logdir (/var/log/tarantool). So we need
	# to set it manually in tarantoolctl configuration file.
	#
	# The tarantoolctl tool is removed in the series-3 releases. See [1] for
	# details.
	#
	# [1]: https://github.com/tarantool/tarantool/issues/9443
	if ver_test ${PV} -le 3.0; then
		sed -e "s#@TARANTOOL_RUNDIR@#${TARANTOOL_RUNDIR}#g" \
			-i extra/dist/default/tarantool.in
		grep "${TARANTOOL_RUNDIR}" extra/dist/default/tarantool.in || \
			die "patch rundir"
	fi

	echo "d ${TARANTOOL_RUNDIR} 0750 ${TARANTOOL_USER} ${TARANTOOL_GROUP} -" > \
		extra/tarantool.tmpfiles.conf || die "create tmpfiles conf"

	# Necessary for building with glibc-2.34.
	#
	# https://github.com/tarantool/tarantool/issues/6686
	#
	# The fix land into 1.10.11-63-gbe0f44de1, 2.8.2-83-gbba7a2fad,
	# 2.10.0-beta1-377-g9c01b325a, but the version check is a bit
	# tricky, so just find the erroneous pattern in the code.
	grep '^static char stack_buf\[SIGSTKSZ\];$' test/unit/guard.cc && \
		eapply "${FILESDIR}/gh-6686-fix-build-with-glibc-2-34.patch"

	cmake_src_prepare
}

src_configure() {
	if use debug; then
		export CMAKE_BUILD_TYPE=Debug
	else
		export CMAKE_BUILD_TYPE=RelWithDebInfo
	fi

	# https://github.com/tarantool/gentoo-overlay/issues/73
	if use system-zstd; then
		CFLAGS="$CFLAGS -Wno-deprecated-declarations"
		CXXFLAGS="$CXXFLAGS -Wno-deprecated-declarations"
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
		-DENABLE_BUNDLED_LIBCURL=$(usex system-libcurl OFF ON)
		-DENABLE_BUNDLED_LIBYAML=$(usex system-libyaml OFF ON)
		-DENABLE_BUNDLED_ZSTD="$(usex system-zstd OFF ON)"
		-DENABLE_FEEDBACK_DAEMON="$(usex feedback-daemon)"
		-DEMBED_LUAROCKS="$(usex embed-luarocks)"
	)
	cmake_src_configure
}

src_test() {
	pushd "${BUILD_DIR}" > /dev/null || die
	emake test
	popd > /dev/null || die
}

src_install() {
	# User guide
	dodoc README.md
	dodoc AUTHORS
	dodoc TODO

	# Server binary and plugins
	cmake_src_install

	# Keep run directory
	newtmpfiles extra/tarantool.tmpfiles.conf ${PN}.conf

	# Data directory
	keepdir /var/lib/tarantool

	# Lua scrips
	keepdir /usr/share/tarantool

	# Init script
	#
	# The init script is based on the tarantoolctl tool, which is removed in
	# 3.0 and 3.1 releases. See [1] for details.
	#
	# [1]: https://github.com/tarantool/tarantool/issues/9443
	if ver_test ${PV} -le 3.0; then
		newinitd "${FILESDIR}/tarantool.initd" tarantool
	fi

	# Log directory
	keepdir /var/log/tarantool
	fowners "${TARANTOOL_USER}:${TARANTOOL_GROUP}" /var/log/tarantool
}

pkg_postinst() {
	# Create a run directory
	tmpfiles_process ${PN}.conf

	if use feedback-daemon; then
		elog "You have feedback-daemon USE flag enabled."
		elog "This enables sending information about long-running (> 1 hour)"
		elog "instances to [1] by default. See [2] for more information, "
		elog "especially [3]."
		elog
		elog "[1]: https://feedback.tarantool.io"
		elog "[2]: https://github.com/tarantool/tarantool/commit/2ae373ae741dcf975c5d176316d8290c962446ba"
		elog "[3]: https://github.com/tarantool/tarantool/commit/2ae373ae741dcf975c5d176316d8290c962446ba#diff-82b4b8a83aa989c9defd5b9fb1a13999R28"
		elog
	fi
}
