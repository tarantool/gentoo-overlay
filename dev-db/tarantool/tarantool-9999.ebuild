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
IUSE="+backtrace debug feedback-daemon gcov gprof system-zstd systemd test cpu_flags_x86_sse2 cpu_flags_x86_avx"

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
	system-zstd? ( app-arch/zstd )
	dev-libs/icu
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

src_prepare() {
	if [[ ${PVR} =~ 1\.7\.[56].* || ${PVR} =~ 1\.8\.2.* ]]; then
		epatch "${FILESDIR}/tarantool-1.7.5-march-native.patch"
	fi
	if ! use feedback-daemon && (
			([[ ${PV} =~ 1.* ]] && version_is_at_least 1.10.0.28) || \
			([[ ${PV} =~ 2.* ]] && version_is_at_least 2.0.4.163) || \
			[[ ${PV} == 9999 ]]); then
		# revert 2ae373ae741dcf975c5d176316d8290c962446ba in more or less
		# robust way; until [1] is not fixed
		# [1]: https://github.com/tarantool/tarantool/issues/3308
		local comment='disabled by USE=-feedback-daemon'
		sed -e 's@^lua_source(lua_sources lua/feedback_daemon\.lua)$@# \0 # '"${comment}@" \
			-i src/box/CMakeLists.txt || die "sed feedback-daemon 1"
		sed -e 's@^\s*feedback_daemon_lua\[\],$@// \0 // '"${comment}@" \
			-e 's@^\s*"box/feedback_daemon", feedback_daemon_lua,@// \0 // '"${comment}@" \
			-i src/box/lua/init.c || die "sed feedback-daemon 2"
		sed -e 's@^\s*feedback_enabled *=.*$@-- \0 -- '"${comment}@" \
			-e 's@^\s*feedback_host *=.*$@-- \0 -- '"${comment}@" \
			-e 's@^\s*feedback_interval *=.*$@-- \0 -- '"${comment}@" \
			-i src/box/lua/load_cfg.lua || die "sed feedback-daemon 3"
		echo 'box.feedback = nil' >> src/box/lua/schema.lua \
			|| die "echo box.feedback"
		rm src/box/lua/feedback_daemon.lua || die "rm feedback_daemon.lua"
	fi
	default
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
		-DENABLE_BUNDLED_LIBYAML=OFF
		-DENABLE_BUNDLED_ZSTD="$(usex system-zstd OFF ON)"
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

	# Run directory
	keepdir /var/run/tarantool
	fowners "${TARANTOOL_USER}:${TARANTOOL_GROUP}" /var/run/tarantool

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
	if use feedback-daemon; then
		elog "You have feedback-daemon USE flag enabled."
		elog "This enables sending information about long-running (> 1 hour)"
		elog "instances to [1] by default. See [2] for more information, "
		elog "especially [3]."
		elog
		elog "[1]: https://feedback.tarantool.io"
		elog "[2]: https://github.com/tarantool/tarantool/commit/2ae373ae741dcf975c5d176316d8290c962446ba"
		elog "[3]: https://github.com/tarantool/tarantool/commit/2ae373ae741dcf975c5d176316d8290c962446ba#diff-82b4b8a83aa989c9defd5b9fb1a13999R28"
	fi
	elog
}
