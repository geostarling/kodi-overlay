EAPI="5"

RELEASE_NAME="Helix"

# Does not work with py3 here
# It might work with py:2.5 but I didn't test that
PYTHON_COMPAT=( python{2_6,2_7} )
PYTHON_REQ_USE="sqlite"

inherit eutils python-single-r1 multiprocessing autotools

case ${PV} in
9999)
	EGIT_REPO_URI="git://github.com/xbmc/xbmc.git"
	inherit git-2
	;;
*_alpha*)
	MY_PV="${PV/_alpha/a}-$RELEASE_NAME"
	SRC_URI="https://github.com/xbmc/xbmc/archive/${MY_PV}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	;;
*_beta*)
	MY_PV="${PV/_beta/b}-$RELEASE_NAME"
	SRC_URI="https://github.com/xbmc/xbmc/archive/${MY_PV}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	;;
*_rc*)
	MY_PV="${PV/_rc/rc}-$RELEASE_NAME"
	SRC_URI="https://github.com/xbmc/xbmc/archive/${MY_PV}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	;;
*)
	MY_PV="${PV}-$RELEASE_NAME"
	SRC_URI="http://mirrors.kodi.tv/releases/source/${MY_PV}.tar.gz"

	# For some reason, the upstream stil inculded an 'xbmc-' prefix
	# on their download mirror for 14.0.
	MY_PV="xbmc-${PV}-$RELEASE_NAME"

	KEYWORDS="~amd64 ~x86"
	;;
esac

DESCRIPTION="Kodi is a free and open source media-player and entertainment hub"
HOMEPAGE="http://kodi.tv/"

LICENSE="GPL-2"
SLOT="0"
IUSE="afp airplay alsa altivec avahi bluetooth bluray caps cec css debug +fishbmc gles goom java joystick midi mysql nfs +opengl profile +projectm pulseaudio pvr +rsxs rtmp +samba +sdl sse sse2 sftp test upnp udisks upower +usb vaapi vdpau webserver +X +xrandr"
REQUIRED_USE="
	pvr? ( mysql )
	rsxs? ( X )
	X? ( sdl )
	xrandr? ( X )
"

COMMON_DEPEND="${PYTHON_DEPS}
	app-arch/bzip2
	app-arch/unzip
	app-arch/zip
	app-i18n/enca
	airplay? (
		app-pda/libplist
		media-plugins/kodi-addon-libshairplay
	)
	dev-libs/boost
	dev-libs/fribidi
	dev-libs/libcdio[-minimal]
	cec? ( >=dev-libs/libcec-2.1 )
	dev-libs/libpcre[cxx]
	>=dev-libs/lzo-2.04
	dev-libs/tinyxml[stl]
	dev-libs/yajl
	dev-python/simplejson[${PYTHON_USEDEP}]
	media-fonts/corefonts
	media-fonts/roboto
	media-libs/alsa-lib
	media-libs/flac
	media-libs/fontconfig
	media-libs/freetype
	>=media-libs/glew-1.5.6
	media-libs/jasper
	media-libs/jbigkit
	>=media-libs/libass-0.9.7
	bluray? ( media-libs/libbluray )
	css? ( media-libs/libdvdcss )
	media-libs/libmad
	media-libs/libmodplug
	media-libs/libmpeg2
	media-libs/libogg
	media-libs/libpng
	projectm? ( media-libs/libprojectm )
	media-libs/libsamplerate
	sdl? ( media-libs/libsdl[opengl,sound,video,X] )
	alsa? ( media-libs/libsdl[alsa] )
	>=media-libs/taglib-1.8
	media-libs/libvorbis
	sdl? (
		media-libs/sdl-gfx
		>=media-libs/sdl-image-1.2.10[gif,jpeg,png]
		media-libs/sdl-mixer
		media-libs/sdl-sound
	)
	media-libs/tiff
	pulseaudio? ( media-sound/pulseaudio )
	media-sound/wavpack
	rtmp? ( media-video/rtmpdump )
	avahi? ( net-dns/avahi )
	afp? ( net-fs/afpfs-ng )
	nfs? ( net-fs/libnfs )
	webserver? ( net-libs/libmicrohttpd[messages] )
	sftp? ( net-libs/libssh[sftp] )
	net-misc/curl
	samba? ( >=net-fs/samba-3.4.6[smbclient] )
	bluetooth? ( net-wireless/bluez )
	sys-apps/dbus
	caps? ( sys-libs/libcap )
	sys-libs/zlib
	virtual/jpeg
	usb? ( virtual/libusb )
	mysql? ( virtual/mysql )
	opengl? (
		virtual/glu
		virtual/opengl
	)
	gles? ( virtual/opengl )
	vaapi? ( x11-libs/libva[opengl] )
	vdpau? ( || ( x11-libs/libvdpau >=x11-drivers/nvidia-drivers-180.51 ) )
	X? (
		x11-apps/xdpyinfo
		x11-apps/mesa-progs
		x11-libs/libXinerama
		xrandr? ( x11-libs/libXrandr )
		x11-libs/libXrender
	)"
RDEPEND="${COMMON_DEPEND}
	udisks? ( sys-fs/udisks:0 )
	upower? ( || ( sys-power/upower sys-power/upower-pm-utils ) )"
DEPEND="${COMMON_DEPEND}
	app-arch/xz-utils
	dev-lang/swig
	dev-util/gperf
	X? ( x11-proto/xineramaproto )
	dev-util/cmake
	x86? ( dev-lang/nasm )
	java? ( virtual/jre )
	test? ( dev-cpp/gtest )"
# Force java for latest git version to avoid having to hand maintain the
# generated addons package. #488118
[[ ${PV} == "9999" ]] && DEPEND+=" virtual/jre"

S=${WORKDIR}/${MY_PV}

pkg_setup() {
	python-single-r1_pkg_setup
}

src_unpack() {
	[[ ${PV} == "9999" ]] && git-2_src_unpack || default
}

src_prepare() {
	epatch "${FILESDIR}"/${PN}-9999-nomythtv.patch
	epatch "${FILESDIR}"/${PN}-9999-no-arm-flags.patch #400617
	epatch "${FILESDIR}"/${PN}-13.0-system-projectm.patch
	# The mythtv patch touches configure.ac, so force a regen
	rm -f configure

	# some dirs ship generated autotools, some dont
	multijob_init
	local d
	for d in $(printf 'f:\n\t@echo $(BOOTSTRAP_TARGETS)\ninclude bootstrap.mk\n' | emake -f - f) ; do
		[[ -e ${d} ]] && continue
		pushd ${d/%configure/.} >/dev/null || die
		AT_NOELIBTOOLIZE="yes" AT_TOPLEVEL_EAUTORECONF="yes" \
		multijob_child_init eautoreconf
		popd >/dev/null
	done
	multijob_finish
	elibtoolize

	emake -f codegenerator.mk

	# Disable internal func checks as our USE/DEPEND
	# stuff handles this just fine already #408395
	export ac_cv_lib_avcodec_ff_vdpau_vc1_decode_picture=yes

	local squish #290564
	use altivec && squish="-DSQUISH_USE_ALTIVEC=1 -maltivec"
	use sse && squish="-DSQUISH_USE_SSE=1 -msse"
	use sse2 && squish="-DSQUISH_USE_SSE=2 -msse2"
	sed -i \
		-e '/^CXXFLAGS/{s:-D[^=]*=.::;s:-m[[:alnum:]]*::}' \
		-e "1iCXXFLAGS += ${squish}" \
		lib/libsquish/Makefile.in || die

	# Fix XBMC's final version string showing as "exported"
	# instead of the SVN revision number.
	export HAVE_GIT=no GIT_REV=${EGIT_VERSION:-exported}

	# avoid long delays when powerkit isn't running #348580
	sed -i \
		-e '/dbus_connection_send_with_reply_and_block/s:-1:3000:' \
		xbmc/linux/*.cpp || die

	epatch_user #293109

	# Tweak autotool timestamps to avoid regeneration
	find . -type f -print0 | xargs -0 touch -r configure
}

src_configure() {
	# Disable documentation generation
	export ac_cv_path_LATEX=no
	# Avoid help2man
	export HELP2MAN=$(type -P help2man || echo true)
	# No configure flage for this #403561
	export ac_cv_lib_bluetooth_hci_devid=$(usex bluetooth)
	# Requiring java is asine #434662
	export ac_cv_path_JAVA_EXE=$( which $(usex java java true) )

	econf \
		--docdir=/usr/share/doc/${PF} \
		--disable-ccache \
		--disable-optimizations \
		--enable-gl \
		$(use_enable afp afpclient) \
		$(use_enable airplay) \
		$(use_enable avahi) \
		$(use_enable bluray libbluray) \
		$(use_enable cec libcec) \
		$(use_enable css dvdcss) \
		$(use_enable debug) \
		$(use_enable fishbmc) \
		$(use_enable gles) \
		$(use_enable goom) \
		$(use_enable joystick) \
		$(use_enable midi mid) \
		$(use_enable mysql) \
		$(use_enable nfs) \
		$(use_enable opengl gl) \
		$(use_enable profile profiling) \
		$(use_enable projectm) \
		$(use_enable pulseaudio pulse) \
		$(use_enable pvr mythtv) \
		$(use_enable rsxs) \
		$(use_enable rtmp) \
		$(use_enable samba) \
		$(use_enable sdl) \
		$(use_enable sftp ssh) \
		$(use_enable test gtest) \
		$(use_enable usb libusb) \
		$(use_enable upnp) \
		$(use_enable vaapi) \
		$(use_enable vdpau) \
		$(use_enable webserver) \
		$(use_enable X x11) \
		$(use_enable xrandr)
}

src_install() {
	default
	rm "${ED}"/usr/share/doc/*/{LICENSE.GPL,copying.txt}*

	domenu tools/Linux/kodi.desktop
	newicon media/icon48x48.png kodi.png

	# Remove optional addons (platform specific and disabled by USE flag).
	local disabled_addons=(
		repository.pvr-{android,ios,osx{32,64},win32}.xbmc.org
		visualization.dxspectrum
	)
	use fishbmc  || disabled_addons+=( visualization.fishbmc )
	use projectm || disabled_addons+=( visualization.{milkdrop,projectm} )
	use rsxs     || disabled_addons+=( screensaver.rsxs.{euphoria,plasma,solarwinds} )
	rm -rf "${disabled_addons[@]/#/${ED}/usr/share/kodi/addons/}"

	# Punt simplejson bundle, we use the system one anyway.
	rm -rf "${ED}"/usr/share/kodi/addons/script.module.simplejson/lib
	# Remove fonconfig settings that are used only on MacOSX.
	# Can't be patched upstream because they just find all files and install
	# them into same structure like they have in git.
	rm -rf "${ED}"/usr/share/kodi/system/players/dvdplayer/etc

	# Replace bundled fonts with system ones
	# teletext.ttf: unknown
	# bold-caps.ttf: unknown
	# roboto: roboto-bold, roboto-regular
	# arial.ttf: font mashed from droid/roboto, not removed wrt bug#460514
	rm -rf "${ED}"/usr/share/kodi/addons/skin.confluence/fonts/Roboto-*
	dosym /usr/share/fonts/roboto/Roboto-Regular.ttf \
		/usr/share/kodi/addons/skin.confluence/fonts/Roboto-Regular.ttf
	dosym /usr/share/fonts/roboto/Roboto-Bold.ttf \
		/usr/share/kodi/addons/skin.confluence/fonts/Roboto-Bold.ttf

	python_domodule tools/EventClients/lib/python/xbmcclient.py
	python_newscript "tools/EventClients/Clients/Kodi Send/kodi-send.py" kodi-send
}

pkg_postinst() {
	elog "Visit http://kodi.wiki/"
}
