# btusb-barrot-dkms

Patched `btusb` driver (DKMS) for Bluetooth USB adapters with a **Barrot** chip,
such as the **UGREEN Bluetooth 5.4 adapter** (`33fa:0010`), packaged for Arch Linux.

**Installation guide:** [English](docs/INSTALL.md) · [Español](docs/INSTALL.es.md)

## The problem

With the stock kernel driver the adapter drops off USB and reconnects every few
seconds, and BLE devices (keyboards, mice, game controllers) cannot pair or stay
connected:

```
Bluetooth: hci0: command 0x2041 tx timeout
Bluetooth: hci0: Opcode 0x2041 failed: -110
usb 1-5: USB disconnect, device number 76
```

The chip reports support for LE extended scanning, but stops responding as soon
as the kernel uses it (HCI command `0x2041`). The adapter resets, re-enumerates,
and the same thing happens again.

## What the patch changes

Only for Barrot devices (`33fa:0010`, `33fa:0012`), inside `btusb`:

- Sets `HCI_QUIRK_BROKEN_EXT_SCAN` and `HCI_QUIRK_BROKEN_EXT_CREATE_CONN`, so the
  kernel uses the legacy LE scan and connect commands.
- Hides the LE Extended Advertising feature bit: once an extended command has
  been sent, the chip rejects the legacy ones with *Command Disallowed*.
- Completes *LE Read Remote Used Features* locally instead of sending it to the
  chip, which answers it with *Controller Busy* right after connecting and makes
  the kernel drop the link.

## Surviving kernel updates

- DKMS rebuilds the module for every kernel, from the exact `btusb.c` of that
  kernel version (kernel.org stable/torvalds trees, or the gregkh GitHub mirror).
- pacman 7.1+ runs hooks without network access, so a hook with
  `NetworkAccess = allowed` caches the sources before the DKMS hook builds.
- Offline during an update, it builds from a cached copy of the same kernel
  series and rebuilds with the exact sources on the next boot with network.
- A udev rule starts `btusb-barrot-autofix.service` when the adapter shows up:
  it builds the module if it is missing and reloads it if a stale one is loaded.
- An autostart entry shows a desktop notification if that fails.
- When a kernel ships the official fix, the package builds `btusb` unpatched and
  the pacman hook tells you it can be removed.

## Requirements

- Arch Linux or a derivative with pacman 7.1 or newer
- Kernel 6.18 or newer (the Barrot device IDs appeared in 6.18) and its headers
  (`linux-headers`, `linux-lts-headers`, ...). Older kernels are skipped.

## Install

Quick version below. The [installation guide](docs/INSTALL.md)
([en español](docs/INSTALL.es.md)) covers checking that you have this adapter,
installing the kernel headers, verifying the fix, pairing BLE devices and
troubleshooting.

```sh
git clone https://github.com/andrefdev/btusb-barrot-dkms.git
cd btusb-barrot-dkms
makepkg -si
```

The patched driver is loaded at the end of the install. To check it:

```sh
dkms status btusb-barrot
sudo dmesg | grep Barrot    # Barrot: hiding LE extended advertising
```

If the adapter ever misbehaves after a kernel update:

```sh
sudo btusb-barrot-fix
```

## Uninstall

```sh
sudo pacman -R btusb-barrot-dkms
sudo modprobe -r btusb && sudo modprobe btusb
```

## Tested with

- UGREEN Bluetooth 5.4 adapter, `33fa:0010`, bcdDevice 88.91
- CachyOS, kernels 7.3.1 (clang/ThinLTO) and 6.18.55 LTS
- Logitech K250 BLE keyboard

`33fa:0012` (UGREEN Bluetooth 6.0) takes the same code path but has not been
tested. Reports are welcome in the issues.

## Upstream status

A proper fix is under review in
[bluez/bluetooth-next#1035](https://github.com/bluez/bluetooth-next/pull/1035).
Once it is in your kernel, this package is no longer needed.

See also [omocatodico/btusb-barrot](https://github.com/omocatodico/btusb-barrot),
a similar DKMS workaround aimed at other distributions.

## License

GPL-2.0-or-later, the same as the kernel's `btusb.c`.
