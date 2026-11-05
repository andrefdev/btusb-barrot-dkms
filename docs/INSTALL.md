# Installation guide

[Versión en español](INSTALL.es.md)

This guide covers Bluetooth USB adapters with a **Barrot** chip, such as the
**UGREEN Bluetooth 5.4** (`33fa:0010`), on Arch Linux and derivatives
(EndeavourOS, CachyOS, Garuda...).

## 1. Do you have this problem?

Check that your adapter uses the Barrot chip:

```sh
lsusb | grep -i 33fa
```

If you see `ID 33fa:0010` (UGREEN BT5.4) or `ID 33fa:0012` (UGREEN BT6.0), this
package is for you. With the stock kernel driver, the log shows this loop every
few seconds:

```sh
journalctl -k -b | grep -E '0x2041|UGREEN|USB disconnect'
```

```
Bluetooth: hci0: command 0x2041 tx timeout
usb 1-5: USB disconnect, device number 76
usb 1-5: Product: UGREEN BT5.4 Adapter
```

## 2. Requirements

**pacman 7.1 or newer:**

```sh
pacman -V
```

**Kernel 6.18 or newer.** Barrot support appeared in 6.18; older kernels are
skipped.

```sh
uname -r
```

**The headers for every kernel you use.** Without them DKMS cannot build the
driver for that kernel:

| Kernel | Headers package |
|---|---|
| `linux` | `linux-headers` |
| `linux-lts` | `linux-lts-headers` |
| `linux-zen` | `linux-zen-headers` |
| `linux-hardened` | `linux-hardened-headers` |
| `linux-cachyos` | `linux-cachyos-headers` |
| `linux-cachyos-lts` | `linux-cachyos-lts-headers` |

For example, with the stock Arch kernel:

```sh
sudo pacman -S --needed base-devel git linux-headers
```

## 3. Install

```sh
git clone https://github.com/andrefdev/btusb-barrot-dkms.git
cd btusb-barrot-dkms
makepkg -si
```

During the install, pacman downloads the `btusb` source for your kernel, builds
it with DKMS for every kernel that has headers (under a minute) and loads the
patched driver. No reboot needed.

> Once the package is on the AUR you will also be able to install it with
> `yay -S btusb-barrot-dkms` or `paru -S btusb-barrot-dkms`.

## 4. Check that it works

```sh
dkms status btusb-barrot
```

It should say `installed` for every kernel:

```
btusb-barrot/1.3, 7.3.1-1-cachyos, x86_64: installed
```

```sh
sudo dmesg | grep Barrot
```

You should see `Barrot: hiding LE extended advertising`. If not, unplug the
adapter and plug it back in.

Run a BLE scan, which is exactly what used to knock the adapter off:

```sh
bluetoothctl --timeout 15 scan on
```

If devices show up and `journalctl -k -b | grep 0x2041` shows no new errors, it
works.

## 5. Pair a BLE keyboard, mouse or controller

Use your desktop's Bluetooth settings, or `bluetoothctl` in interactive mode:

```
$ bluetoothctl
[bluetoothctl]> scan on
    (put the device in pairing mode)
[bluetoothctl]> pair XX:XX:XX:XX:XX:XX
[bluetoothctl]> trust XX:XX:XX:XX:XX:XX
[bluetoothctl]> connect XX:XX:XX:XX:XX:XX
```

If a code is shown, type it on the device and press Enter.

Logitech keyboards change their address on every pairing attempt. If the list
shows an old entry that never connects, remove it with
`bluetoothctl remove XX:XX:XX:XX:XX:XX` and pair the new one.

## 6. Kernel updates

Nothing to do. When the kernel is updated pacman shows:

```
(3/9) Fetching btusb sources for the Barrot Bluetooth patch...
(4/9) Install DKMS modules
==> dkms install --no-depmod btusb-barrot/1.3 -k <new kernel>
(6/9) Checking the Barrot Bluetooth patch (btusb-barrot)...
```

If something fails, the package retries when the adapter shows up, and if it
still cannot build, it shows a desktop notification.

To update the package itself:

```sh
cd btusb-barrot-dkms
git pull
makepkg -si
```

## 7. Troubleshooting

**The adapter still keeps disconnecting**

```sh
sudo btusb-barrot-fix
modinfo -n btusb
```

The path must contain `updates/dkms`. If it contains `kernel/drivers`, the
stock driver is in use.

**See what happened**

```sh
journalctl -u btusb-barrot-autofix.service -b
cat /var/lib/dkms/btusb-barrot/*/$(uname -r)/x86_64/log/make.log
```

**Headers missing for a kernel.** Install them (table in section 2) and run
`sudo btusb-barrot-fix`.

**Secure Boot enabled.** The kernel only loads signed modules. Set up DKMS
module signing (`mok_signing_key` and `mok_certificate` in
`/etc/dkms/framework.conf`) and enroll the key with `mokutil --import`.

**`bluetoothctl pair` says "No agent available".** Use `bluetoothctl` in
interactive mode (section 5) or your desktop's Bluetooth settings.

## 8. Uninstall

```sh
sudo pacman -R btusb-barrot-dkms
sudo modprobe -r btusb && sudo modprobe btusb
```

Once your kernel ships the official fix, pacman tells you the package can be
removed.

## 9. Report a problem

Open an [issue](https://github.com/andrefdev/btusb-barrot-dkms/issues) with the
output of:

```sh
lsusb | grep -i 33fa
uname -r
dkms status btusb-barrot
journalctl -k -b | grep -iE 'hci0|barrot|33fa|bluetooth' | tail -50
```
