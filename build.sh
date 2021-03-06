#! /usr/bin/env bash
#
# Build rTorrent including patches
#

# Yep, 0.9.4 is the default now
export RT_MINOR=4
export LT_VERSION=0.13.$RT_MINOR; export RT_VERSION=0.9.$RT_MINOR;
#export RT_MINOR=9
#export LT_VERSION=0.12.$RT_MINOR; export RT_VERSION=0.8.$RT_MINOR;
export SVN=0 # no git support yet!

# Fitting / tested dependency versions for major platforms
export CARES_VERSION=1.7.5
export CURL_VERSION=7.22.0
export XMLRPC_REV=2366

case "$(lsb_release -cs)" in
    trusty)
        export CARES_VERSION=1.10.0
        export CURL_VERSION=7.38.0
        export XMLRPC_REV=2626 # Release 1.38.04
        ;;
esac

# Extra "configure" options for libtorrent and rtorrent
export CFG_OPTS=""
##export CFG_OPTS="--enable-debug --enable-extra-debug"

# try this when you get configure errors regarding xmlrpc-c
#export CFLAGS="$CFLAGS -march=i586"

# AUR Patches (do NOT touch these)
_magnet_uri=0
_ipv6=0
_ip_filter=0
_friend=0
_bad_peer_handling=0
# 1 = canvas color patch / 2 = karabja mod patch / 3 = PyroScope UI
_interface=3
_show_idle_times=0
_trackerinfo=1
# 1 = tjwoosta vi keybindings / 2 = akston vi keybindings
_keybindings=0


#
# HERE BE DRAGONS!
#

# Fix people's broken systems
test "$(tr A-Z a-z <<<${LANG/*.})" = "utf-8" || export LANG=en_US.UTF-8
unset LC_ALL
export LC_ALL

# Platform magic
export SED_I="sed -i -e"
case "$(uname -s)" in
    FreeBSD)
        export CFLAGS="-pipe -O2 -pthread ${CFLAGS}"
        export LDFLAGS="-s -lpthread ${LDFLAGS}"
        export SED_I="sed -i '' -e"
        ;;
    Linux)
        export CPPFLAGS="-pthread ${CPPFLAGS}"
        export LIBS="-lpthread ${LIBS}"
        ;;
esac

# Keep rTorrent version, once it was built in this directory
test -d rtorrent-0.8.6 && { export LT_VERSION=0.12.6; export RT_VERSION=0.8.6; }
test -d rtorrent-0.8.8 && { export LT_VERSION=0.12.8; export RT_VERSION=0.8.8; }
test -d rtorrent-0.8.9 && { export LT_VERSION=0.12.9; export RT_VERSION=0.8.9; }
test -d rtorrent-0.9.2 && { export LT_VERSION=0.13.2; export RT_VERSION=0.9.2; }
test -d rtorrent-0.9.4 && { export LT_VERSION=0.13.4; export RT_VERSION=0.9.4; }
test -d SVN-HEAD -o ${SVN:-0} = 1 && { export LT_VERSION=0.12.9; export RT_VERSION=0.8.9-svn; export SVN=1; }

# Incompatible patches
test $RT_VERSION = 0.9.2 && _trackerinfo=0
test $RT_VERSION = 0.9.4 && _trackerinfo=0

export PKG_INST_DIR="/opt/rtorrent"
export INST_DIR="$HOME/lib/rtorrent-$RT_VERSION"

set_build_env() {
    local dump="$1"
    local quot="$2"
    $dump export CPPFLAGS="$quot-I $INST_DIR/include ${CPPFLAGS}$quot"
    $dump export CXXFLAGS="$quot$CFLAGS$quot"
    $dump export LDFLAGS="$quot-L$INST_DIR/lib ${LDFLAGS}$quot"
    $dump export PKG_CONFIG_PATH="$quot$INST_DIR/lib/pkgconfig${PKG_CONFIG_PATH:+:}${PKG_CONFIG_PATH}$quot"
}

SELF_URL=https://github.com/pyroscope/rtorrent-ps.git
XMLRPC_URL="http://svn.code.sf.net/p/xmlrpc-c/code/advanced@$XMLRPC_REV"
TARBALLS=$(cat <<.
http://c-ares.haxx.se/download/c-ares-$CARES_VERSION.tar.gz
http://curl.haxx.se/download/curl-$CURL_VERSION.tar.gz
.
)
test ${SVN:-0} = 0 && TARBALLS=$(cat <<.
$TARBALLS
http://libtorrent.rakshasa.no/downloads/libtorrent-$LT_VERSION.tar.gz
http://libtorrent.rakshasa.no/downloads/rtorrent-$RT_VERSION.tar.gz
.
)


BUILD_DEPS=$(cat <<.
wget:wget
subversion:svn
build-essential:make
build-essential:g++
patch:patch
libtool:libtoolize
automake:aclocal
autoconf:autoconf
automake:automake
pkg-config:pkg-config
.
)

set -e
set +x
export SRC_DIR=$(cd $(dirname $0) && pwd)
SUBDIRS="c-ares-*[0-9] curl-*[0-9] xmlrpc-c-advanced-$XMLRPC_REV libtorrent-*[0-9] rtorrent-*[0-9] rtorrent-extended"
ESC=$(echo -en \\0033)
BOLD="$ESC[1m"
OFF="$ESC[0m"


#
# HELPERS
#
bold() {
    echo "$BOLD$1$OFF"
}

fail() {
    bold "$@"
    exit 1
}

check_deps() {
    for dep in $BUILD_DEPS; do
        pkg=${dep%%:*}
        cmd=${dep##*:}
        if which $cmd >/dev/null; then :; else
            echo "You don't have the '$cmd' command available, you likely need to:"
            bold "    sudo apt-get install $pkg"
            exit 1
        fi
    done
}

aur_patches() {
    #ex
    if [[ "${_magnet_uri}" = "1" || "${_ipv6}" = "1" ]]; then
        bold "ex_magnet_uri.patch"
        patch -uNp1 -i "${srcdir}/ex_magnet_uri.patch"
    fi
    if [[ "${_ipv6}" = "1" ]]; then
        bold "ex_ip6.patch"
        patch -uNp1 -i "${srcdir}/ex_ipv6.patch"
        _cfg_opts="--enable-ipv6"
    fi
    if [[ "${_ip_filter}" = "1" || "${_friend}" = "1" ]]; then
        bold "ex_ip_filter.patch"
        patch -uNp1 -i "${srcdir}/ex_ip_filter.patch"
    fi
    if [[ "${_friend}" = "1" ]]; then
        bold "ex_friend.patch"
        patch -uNp1 -i "${srcdir}/ex_friend.patch"
    fi
    if [[ "${_bad_peer_handling}" = "1" ]]; then
        bold "ex_bad_peer_handling.patch"
        patch -uNp1 -i "${srcdir}/ex_bad_peer_handling.patch"
    fi

    #ui
    if [[ "${_interface}" = "1" ]]; then
        bold "ui_canvas_color.patch"
        patch -uNp1 -i "${srcdir}/ui_canvas_color.patch"
    elif [[ "${_interface}" = "2" ]]; then
        bold "ui_karabaja_mod.patch"
        patch -uNp1 -i "${srcdir}/ui_karabaja_mod.patch"
    fi
    if [[ "${_show_idle_times}" = "1" ]]; then
        bold "ui_show_idle_times.patch"
        patch -uNp1 -i "${srcdir}/ui_show_idle_times.patch"
    fi
    if [[ "${_trackerinfo}" = "1" ]]; then
        bold "ui_trackerinfo.patch"
        patch -uNp1 -i "${srcdir}/ui_trackerinfo.patch"
    fi

    #kb
    if [[ "${_keybindings}" = "1" ]]; then
        bold "kb_vi_tjwoosta.patch"
        patch -uNp1 -i "${srcdir}/kb_vi_tjwoosta.patch"
    elif [[ "${_keybindings}" = "2" ]]; then
        bold "kb_vi_akston.patch"
        patch -uNp1 -i "${srcdir}/kb_vi_akston.patch"
    fi
}

symlink_binary() {
    binary="$INST_DIR/bin/rtorrent"
    flavour="$1"
    test -z "$flavour" || ln -f "$binary" "$binary$flavour"

    mkdir -p ~/bin
    ln -nfs "$binary$flavour" ~/bin/rtorrent-$RT_VERSION
    test -e ~/bin/rtorrent || ln -s rtorrent-$RT_VERSION ~/bin/rtorrent
}


#
# RULES
#
prep() {
    # Create directories
    check_deps
    mkdir -p $INST_DIR/{bin,include,lib,man,share}
    mkdir -p tarballs
}

download() { # Download and unpack sources
    test -d .git || { git clone $SELF_URL tarballs/self ; rm tarballs/self/build.sh; mv tarballs/self/* tarballs/self/.git . ; }

    test -d xmlrpc-c-advanced-$XMLRPC_REV || ( echo "Getting xmlrpc-c r$XMLRPC_REV" && \
        svn -q checkout "$XMLRPC_URL" xmlrpc-c-advanced-$XMLRPC_REV )
    for url in $TARBALLS; do
        url_base=${url##*/}
        test -f tarballs/${url_base} || ( echo "Getting $url_base" && cd tarballs && wget -q $url )
        test -d ${url_base%.tar.gz} || ( echo "Unpacking ${url_base}" && tar xfz tarballs/${url_base} )
        test -d ${url_base%%.tar.gz} || fail "Tarball ${url_base} could not be unpacked"
    done

    if test ${SVN:-0} = 1 -a ! -d SVN-HEAD; then
        svn co svn://rakshasa.no/libtorrent/trunk SVN-HEAD
        ln -nfs SVN-HEAD/libtorrent libtorrent-$LT_VERSION
        ln -nfs SVN-HEAD/rtorrent rtorrent-$RT_VERSION
    fi

    tar xfz patches/rtorrent-extended.tar.gz

    touch tarballs/DONE
}

automagic() {
    aclocal
    rm -f ltmain.sh scripts/{libtool,lt*}.m4
    libtoolize --automake --force --copy
    aclocal
    autoconf
    automake --add-missing
    ./autogen.sh
}

tag_svn_rev() {
    if test ${SVN:-0} = 1; then
        svnrev=$(export LANG=en_US.UTF8 && svn info SVN-HEAD/ | grep ^Revision | cut -f2 -d":" | tr -d " ")
        $SED_I "s% VERSION \"/\"% VERSION \" r$svnrev/\"%" rtorrent-$RT_VERSION/src/ui/download_list.cc
    fi
}

build_deps() {
    # Build direct dependencies
    test -e $SRC_DIR/tarballs/DONE || fail "You need to '$0 download' first!"

    tag_svn_rev

    ( cd c-ares-$CARES_VERSION && ./configure && make && make DESTDIR=$INST_DIR prefix= install )
    $SED_I s:/usr/local:$INST_DIR: $INST_DIR/lib/pkgconfig/*.pc $INST_DIR/lib/*.la
    ( cd curl-$CURL_VERSION && ./configure --enable-ares && make && make DESTDIR=$INST_DIR prefix= install )
    $SED_I s:/usr/local:$INST_DIR: $INST_DIR/lib/pkgconfig/*.pc $INST_DIR/lib/*.la
    ( cd xmlrpc-c-advanced-$XMLRPC_REV \
        && ./configure --prefix=$INST_DIR --with-libwww-ssl \
            --disable-wininet-client --disable-curl-client --disable-libwww-client --disable-abyss-server --disable-cgi-server \
        && make && make install )
    $SED_I s:/usr/local:$INST_DIR: $INST_DIR/bin/xmlrpc-c-config
}

build() { # Build and install all components
    ( cd libtorrent-$LT_VERSION && ( test ${SVN:-0} = 0 || automagic ) \
        && ./configure $CFG_OPTS && make && make DESTDIR=$INST_DIR prefix= install )
    $SED_I s:/usr/local:$INST_DIR: $INST_DIR/lib/pkgconfig/*.pc $INST_DIR/lib/*.la
    ( cd rtorrent-$RT_VERSION && ( test ${SVN:-0} = 0 || automagic ) \
        && ./configure $CFG_OPTS --with-xmlrpc-c=$INST_DIR/bin/xmlrpc-c-config && make && make DESTDIR=$INST_DIR prefix= install )
}

extend() { # Rebuild and install libtorrent and rTorrent with patches applied
    # Based partly on https://aur.archlinux.org/packages/rtorrent-extended/

    test -e $INST_DIR/lib/libxmlrpc.a || fail "You need to '$0 build' first!"

    # Unpack original source
    if test ${SVN:-0} = 0; then
        tar xfz tarballs/libtorrent-$LT_VERSION.tar.gz
        tar xfz tarballs/rtorrent-$RT_VERSION.tar.gz
    else
        # TODO: libtorrent
        ( cd rtorrent-$RT_VERSION && svn revert -R . && svn update )
        tag_svn_rev
    fi

    # Version handling
    [ $RT_VERSION == 0.8.6 -o "$_interface" == 3 ] || { _interface=0; bold "Interface patches disabled"; }
    RT_HEX_VERSION=$(printf "0x%02X%02X%02X" ${RT_VERSION//./ })
    $SED_I "s:\\(AC_DEFINE(HAVE_CONFIG_H.*\\):\1  AC_DEFINE(RT_HEX_VERSION, $RT_HEX_VERSION, for CPP if checks):" rtorrent-$RT_VERSION/configure.ac
    grep "AC_DEFINE.*API_VERSION" rtorrent-$RT_VERSION/configure.ac >/dev/null || \
        $SED_I "s:\\(AC_DEFINE(HAVE_CONFIG_H.*\\):\1  AC_DEFINE(API_VERSION, 0, api version):" rtorrent-$RT_VERSION/configure.ac

    # Patch libtorrent
    pushd libtorrent-$LT_VERSION

    for backport in $SRC_DIR/patches/{backport,trac,misc}_${LT_VERSION%-svn}_*.patch; do
        test ! -e "$backport" || { bold "$(basename $backport)"; patch -uNp0 -i "$backport"; }
    done

    popd
    bold "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    # Patch rTorrent
    pushd rtorrent-$RT_VERSION
    srcdir=$SRC_DIR/rtorrent-extended
    aur_patches

    #echo "fix_ncurses_5.8.patch"
    #patch -uNp1 -i "${srcdir}/fix_ncurses_5.8.patch"

    for filename in $SRC_DIR/patches/*0.8.8.patch; do
        test -e "${filename/0.8.8/0.8.9}" || ln -s "$(basename $filename)" "${filename/0.8.8/0.8.9}"
    done
    test -e $SRC_DIR/patches/ps-ui_pyroscope_0.9.2.patch || ln -s ps-ui_pyroscope_0.8.8.patch $SRC_DIR/patches/ps-ui_pyroscope_0.9.2.patch
    test -e $SRC_DIR/patches/ps-ui_pyroscope_0.9.4.patch || ln -s ps-ui_pyroscope_0.8.8.patch $SRC_DIR/patches/ps-ui_pyroscope_0.9.4.patch

    for corepatch in $SRC_DIR/patches/ps-*_${RT_VERSION%-svn}.patch; do
        test ! -e "$corepatch" || { bold "$(basename $corepatch)"; patch -uNp1 -i "$corepatch"; }
    done

    for backport in $SRC_DIR/patches/{backport,trac,misc}_${RT_VERSION%-svn}_*.patch; do
        test ! -e "$backport" || { bold "$(basename $backport)"; patch -uNp0 -i "$backport"; }
    done

    bold "pyroscope.patch"
    patch -uNp1 -i "$SRC_DIR/patches/pyroscope.patch"
    for i in "$SRC_DIR"/patches/*.{cc,h}; do
        ln -nfs $i src
    done

    if [[ "${_interface}" = "3" ]]; then
        bold "ui_pyroscope.patch"
        patch -uNp1 -i "${SRC_DIR}/patches/ui_pyroscope.patch"
    fi

    # http://libtorrent.rakshasa.no/ticket/2411
    # svn diff -r1184:1186 svn://rakshasa.no/libtorrent/trunk/  >patches/fix_2411_threading.patch
    # svn diff -r1187:1188 svn://rakshasa.no/libtorrent/trunk/ >>patches/fix_2411_threading.patch
    [[ RT_VERSION != 0.8.7 ]] || patch -uNp1 -i "$SRC_DIR/patches/fix_2411_threading.patch"

    $SED_I 's/rTorrent \" VERSION/rTorrent-PS " VERSION/' src/ui/download_list.cc
    popd
    bold "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    # Build it (note that libtorrent patches ALSO influence the "vanilla" version)
    ( set +x ; cd libtorrent-$LT_VERSION && automagic && \
        ./configure $CFG_OPTS && make clean && make && make prefix=$INST_DIR install )
    $SED_I s:/usr/local:$INST_DIR: $INST_DIR/lib/pkgconfig/*.pc $INST_DIR/lib/*.la
    ( set +x ; cd rtorrent-$RT_VERSION && automagic && \
        ./configure $CFG_OPTS --with-xmlrpc-c=$INST_DIR/bin/xmlrpc-c-config >/dev/null && \
        make clean && make && make prefix=$INST_DIR install )
}

clean() { # Clean up generated files
    for i in $SUBDIRS; do
        ( cd $i && make clean )
    done
}

clean_all() { # Remove all downloads and created files
    rm tarballs/*.tar.gz tarballs/DONE >/dev/null || :
    for i in $SUBDIRS; do
        test ! -d $i || rm -rf $i >/dev/null
    done
}

check() { # Print some diagnostic success indicators
    for i in ~/bin/rtorrent{,-$RT_VERSION}; do
        echo $i "->" $(readlink $i) | sed -e "s:$HOME:~:g"
    done
    echo
    echo -n "Check that static linking worked: "
    libs=$(ldd ~/bin/rtorrent-$RT_VERSION | egrep "lib(cares|curl|xmlrpc|torrent)")
    test -n $(echo "$libs" | grep -v "$INST_DIR") && echo OK || echo FAIL
    echo "$libs" | sed -e "s:$HOME:~:g"
}

install() { # Install to $PKG_INST_DIR
    export INST_DIR="$PKG_INST_DIR"
    test -d "$INST_DIR"/. || mkdir -p "$INST_DIR"/
    rm -rf "$INST_DIR"/* || :
    test "$(echo /opt/rtorrent/*)" = "/opt/rtorrent/*" || fail "Could not clean install dir '$INST_DIR'"
    svn up .rev-stamp
    cat >"$INST_DIR"/version-info.sh <<.
RT_PS_VERSION=$RT_VERSION
RT_PS_REVISION=$(svn info .rev-stamp | grep ^Revision: | cut -f2 -d' ')
RT_PS_LT_VERSION=$LT_VERSION
RT_PS_CARES_VERSION=$CARES_VERSION
RT_PS_CURL_VERSION=$CURL_VERSION
RT_PS_XMLRPC_REV=$XMLRPC_REV
.
    clean_all; prep; download;
    set_build_env; build_deps; extend
    #check
}

pkg2deb() { # Package current $PKG_INST_DIR installation
    # You need to:
    #   aptitude install ruby rubygems
    #   gem install fpm
    #   which fpm || ln -s $(ls -1 /var/lib/gems/*/bin/fpm | tail -1) /usr/local/bin
    test -n "$DEBFULLNAME" || fail "You MUST set DEBFULLNAME in your environment"
    test -n "$DEBEMAIL" || fail "You MUST set DEBEMAIL in your environment"

    DIST_DIR=/tmp/rt-ps-dist
    rm -rf "$DIST_DIR" || :
    mkdir -p "$DIST_DIR"

    rm -rf "$PKG_INST_DIR/"{lib/*.a,lib/*.la,lib/pkgconfig,share/man,man,share,include} || :
    rm "$PKG_INST_DIR/bin/"{curl,*-config} || :

    . "$PKG_INST_DIR"/version-info.sh
    deps=$(ldd "$PKG_INST_DIR"/bin/rtorrent | cut -f2 -d'>' | cut -f2 -d' ' | egrep '^/lib/|^/usr/lib/' \
        | xargs -i+ dpkg -S "+" | cut -f1 -d: | sort -u | xargs -i+ echo -d "+")

    ( cd "$DIST_DIR" && fpm -s dir -t deb -n rtorrent-ps \
        -v $RT_PS_VERSION --iteration $RT_PS_REVISION"~"$(lsb_release -cs) \
        -m "\"$DEBFULLNAME\" <$DEBEMAIL>" --category "net" \
        --license "GPL v2" --vendor "https://github.com/rakshasa" \
        --description "Patched and extended ncurses BitTorrent client" \
        --url "https://code.google.com/p/pyroscope/wiki/RtorrentExtended" \
        $deps -C "$PKG_INST_DIR/." --prefix "$PKG_INST_DIR" '.')

    dpkg-deb -c "$DIST_DIR"/*.deb
    echo "~~~" $(find "$DIST_DIR"/*.deb)
    dpkg-deb -I "$DIST_DIR"/*.deb
}

build_everything() { # Go through all build steps
    set_build_env
    build_deps
    build
    symlink_binary -vanilla
    check
}


#
# MAIN
#
cd "$SRC_DIR"
case "$1" in
    all)        prep; download; build_everything ;;
    clean)      clean ;;
    clean_all)  clean_all ;;
    download)   prep; download ;;
    env)        prep; set +x; set_build_env echo '"';;
    build)      prep; build_everything ;;
    extend)     prep
                set_build_env
                test -e $SRC_DIR/rtorrent-$RT_VERSION/src/rtorrent || fail "You need to '$0 all' first!"
                extend
                symlink_binary -extended
                check
                ;;
    check)      check ;;
    install)    install;;
    pkg2deb)    pkg2deb;;
    *)
        echo >&2 "Usage: $0 (all | clean | clean_all | download | build | check | extend )"
        echo >&2 "Build rTorrent $RT_VERSION/$LT_VERSION into $(sed -e s:$HOME/:~/: <<<$INST_DIR)"
        echo >&2
        grep "() { #" $0 | grep -v grep | sort | sed -e "s:^:  :" -e "s:() { #:  @:" | while read i; do
            echo "   " $(eval "echo $i") | tr @ \\t
        done
        exit 1
        ;;
esac
