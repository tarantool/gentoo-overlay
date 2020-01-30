EAPI=6


EGIT_REPO_URI="https://github.com/tarantool/tarantool-c.git"

if [[ ${PV} = 9999* ]]; then
        GIT_ECLASS="git-r3"
fi

inherit eutils cmake-utils $GIT_ECLASS

DESCRIPTION="Tarantool-c connector. Very fast framework, originaly developed by (C)Mail.ru"
HOMEPAGE="http://tarantool.github.io/tarantool-c/index.html"
LICENSE="GPL-2"
SLOT="0"

# may be other arch....
KEYWORDS="~amd64"

# MsgPuck strongly not required, but very recommended.
DEPEND="dev-util/cmake
		dev-libs/msgpuck"


# Ugly hack. Should be removed later.
#LDFLAGS="-luuid -lxml2 -lfcgi -lfcgi++ -lpthread -ldl -lcrypto"
