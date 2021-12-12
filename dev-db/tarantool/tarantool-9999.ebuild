# Copyright 2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

CMAKE_MIN_VERSION=2.6

inherit cmake-utils user versionator tmpfiles

MAJORV=$(get_version_component_range 1)
MINORV=$(get_version_component_range 2)

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
	+backtrace debug feedback-daemon gcov gprof +system-libcurl
	+system-libyaml +system-zstd systemd test cpu_flags_x86_sse2
	cpu_flags_x86_avx
"

RESTRICT="mirror"
SLOT="0/${SERIES}"
LICENSE="BSD-2"

RDEPEND="
	sys-libs/libunwind
	sys-libs/readline:0
	sys-libs/ncurses:0
	dev-libs/libyaml
	system-libcurl? ( >=net-misc/curl-7.65.3 )
	system-libyaml? ( >=dev-libs/libyaml-0.2.2 )
	system-zstd? ( app-arch/zstd )
	dev-libs/icu
"

DEPEND="
	${RDEPEND}
	|| ( >=sys-devel/gcc-4.5[cxx]  >=sys-devel/clang-3.2 )
	test? ( dev-python/gevent dev-python/pyyaml )
"

REQUIRED_USE="
	cpu_flags_x86_avx? ( cpu_flags_x86_sse2 )
"

TARANTOOL_HOME="/var/lib/tarantool"
TARANTOOL_RUNDIR="/run/tarantool"
TARANTOOL_USER=tarantool
TARANTOOL_GROUP=tarantool

pkg_pretend() {
	# clang is not sloted at this moment, we are ok with any installed one.
	if [[ $(tc-getCC) == clang ]]; then
		:
	elif [[ $(gcc-major-version) -lt 4 ]] || {
		[[ $(gcc-major-version) -eq 4 && $(gcc-minor-version) -lt 5 ]]; } then
		 eerror "Compilation with gcc older than 4.5 is not supported"
		 die "Too old gcc found."
	fi

	if ! use system-libcurl && ! ( \
			([[ ${PV} =~ ^1.* ]] && version_is_at_least 1.10.3.120) || \
			([[ ${PV} =~ ^2.1.* ]] && version_is_at_least 2.1.2.155) || \
			([[ ${PV} =~ ^2.2.* ]] && version_is_at_least 2.2.1.19) || \
			([[ ${PV} =~ ^2.3.* ]] && version_is_at_least 2.3.0.42) || \
			[[ ${PV} == 9999 ]]); then
		eerror "USE flag \"system-libcurl\" is disabled, but ${PF} version"
		eerror "is older then needed for using bundled libcurl."
		die "Cannot enable system libcurl."
	fi
}

pkg_setup() {
	ebegin "Creating tarantool user and group"
	enewgroup ${TARANTOOL_GROUP}
	enewuser ${TARANTOOL_USER} -1 -1 "${TARANTOOL_HOME}" ${TARANTOOL_GROUP}
	eend $?
}

src_prepare() {
	# -DENABLE_FEEDBACK_DAEMON=OFF does the job, but it is
	# available only since 2.4.0.231 (see [1]).
	#
	# [1]: https://github.com/tarantool/tarantool/issues/3308
	if ! use feedback-daemon && ! version_is_at_least 2.4.0.231 && ( \
			([[ ${PV} =~ ^1.* ]] && version_is_at_least 1.10.0.28) || \
			([[ ${PV} =~ ^2.* ]] && version_is_at_least 2.0.4.163)); then
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
	sed -e "s#@TARANTOOL_RUNDIR@#${TARANTOOL_RUNDIR}#g" \
		-i extra/dist/default/tarantool.in
	grep "${TARANTOOL_RUNDIR}" extra/dist/default/tarantool.in || \
		die "patch rundir"

	echo "d ${TARANTOOL_RUNDIR} 0750 ${TARANTOOL_USER} ${TARANTOOL_GROUP} -" > \
		extra/dist/tarantool.tmpfiles.conf || die "create tmpfiles conf"

	# Necessary for building with glibc-2.34.
	#
	# https://github.com/tarantool/tarantool/issues/6686
	eapply "${FILESDIR}/gh-6686-fix-build-with-glibc-2-34.patch"

	cmake-utils_src_prepare
}

src_configure() {
	if use debug; then
		export CMAKE_BUILD_TYPE=Debug
	else
		export CMAKE_BUILD_TYPE=RelWithDebInfo
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
	)
	cmake-utils_src_configure
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
	cmake-utils_src_install

	# Keep run directory
	newtmpfiles extra/dist/tarantool.tmpfiles.conf ${PN}.conf

	# Data directory
	keepdir /var/lib/tarantool
	fowners "${TARANTOOL_USER}:${TARANTOOL_GROUP}" /var/log/tarantool

	# Lua scrips
	keepdir /usr/share/tarantool

	# Init script
	newinitd "${FILESDIR}/tarantool.initd" tarantool
}

pkg_postinst() {
	# Create a run directory
	tmpfiles_process ${PN}.conf

	elog
	elog "It is possible to run multiple servers using init.d scrips. Consider"
	elog "the following example:"
	elog
	elog "Create a service:"
	elog "$ vim /etc/tarantool/instances.available/tarantool-myservice.lua"
	elog
	elog "OpenRC:"
	elog "$ ln -s /etc/init.d/tarantool /etc/init.d/tarantool-myservice"
	elog "$ rc-service tarantool-myservice start"
	elog
	elog "Systemd:"
	elog "$ service tarantool@myservice start"
	elog
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
