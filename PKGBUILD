# Maintainer: André Forsyth <50856227+andrefdev at users.noreply.github dot com>
#
# Barrot Bluetooth USB adapters (UGREEN BT5.4, 33fa:0010; also 33fa:0012) claim
# LE extended scanning but hang when it is used, so with the stock btusb they
# drop off the USB bus every few seconds and BLE devices cannot connect. This
# installs a patched btusb (DKMS) that keeps them on the legacy LE commands.
# Needs kernel 6.18 or newer (older kernels are skipped).
#
# Rebuilt automatically for every kernel: a pacman hook with network access
# caches the exact btusb sources before DKMS builds (pacman runs hooks offline),
# a udev-triggered service repairs/reloads the module when the adapter shows
# up, and an autostart entry warns on the desktop if the rebuild failed.
#
# Workaround until the upstream fix lands:
# https://github.com/bluez/bluetooth-next/pull/1035
# When a kernel ships it, the package builds btusb unpatched and says so.
pkgname=btusb-barrot-dkms
pkgver=1.3
pkgrel=1
pkgdesc="Patched btusb for Barrot Bluetooth adapters (UGREEN BT5.4, 33fa:0010): stops the reconnect loop and enables BLE"
arch=(any)
url="https://github.com/andrefdev/btusb-barrot-dkms"
license=(GPL-2.0-or-later)
# 'pacman>=7.1': NetworkAccess in 60-btusb-barrot-fetch.hook
depends=(dkms curl patch 'pacman>=7.1')
optdepends=('libnotify: desktop notice if the module cannot be rebuilt')
install=$pkgname.install
source=(dkms.conf Makefile build.sh fetch-src.sh barrot.patch
        btusb-barrot-fix btusb-barrot-notify btusb-barrot-notify.desktop
        btusb-barrot-autofix.service 90-btusb-barrot.rules
        60-btusb-barrot-fetch.hook 90-btusb-barrot.hook)
sha256sums=('3525e0c3216cc9f7a7ef80c6880b2a345314568968ca2494d7a34e2580813ed4'
            'a4105370136d5252cc0b413546dcb6230b58aa03ca5dff65b0b3a2c77baa9246'
            'a7283253fb02c21b1b4f7f26fc7aa7c3f2fa0e2480deb3e16f73af0807721fa7'
            '77fe55ac22ccb5db719afda00ed6c98e077657927bef77b1ad9367b720eba7a3'
            'df1261f9e9dfde33c5d50cf77063633c51c6944b8139698175114524566c7905'
            'c81a285804405996923c19755ce4be84ff03e6a70a1064ff456da102dd951f76'
            '46d2a617c0f18d87b91461f4fe96c45b0677f41def5e96e96713a70c2dd04846'
            'f4874b3ce957b7230ae0d358558099e47f57fa8b4cb343941e58e31a4e3217a1'
            '42b84b5431edc63590700edade56e64b62fd16cca70d91f23756ca3f8374906b'
            '5f40668e357d36e97846f73da8ed906c5009a45ac1709f264ecd38117740dfe6'
            '3fbb3c44975cb038f09f308d6c40f894d31ab22e8560d8d042d076819d7aeed4'
            '55dc5875d048a5e194403a7899427dc932b59456ffde34abc1d5c32f052ed593')

package() {
	local dst="$pkgdir/usr/src/btusb-barrot-$pkgver"

	install -Dm644 dkms.conf Makefile barrot.patch -t "$dst"
	install -Dm755 build.sh fetch-src.sh -t "$dst"
	sed -i "s/@VER@/$pkgver/" "$dst/dkms.conf"

	install -Dm755 btusb-barrot-fix "$pkgdir/usr/bin/btusb-barrot-fix"
	sed -i "s/@VER@/$pkgver/" "$pkgdir/usr/bin/btusb-barrot-fix"
	install -Dm755 btusb-barrot-notify "$pkgdir/usr/lib/btusb-barrot/notify"
	install -Dm644 btusb-barrot-notify.desktop -t "$pkgdir/etc/xdg/autostart"
	install -Dm644 btusb-barrot-autofix.service -t "$pkgdir/usr/lib/systemd/system"
	install -Dm644 90-btusb-barrot.rules -t "$pkgdir/usr/lib/udev/rules.d"
	install -Dm644 60-btusb-barrot-fetch.hook 90-btusb-barrot.hook -t "$pkgdir/usr/share/libalpm/hooks"
}
