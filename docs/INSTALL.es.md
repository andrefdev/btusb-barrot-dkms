# Guía de instalación

[English version](INSTALL.md)

Esta guía es para adaptadores Bluetooth USB con chip **Barrot**, como el
**UGREEN Bluetooth 5.4** (`33fa:0010`), en Arch Linux o derivadas
(EndeavourOS, CachyOS, Garuda...).

## 1. ¿Tienes este problema?

Comprueba que tu adaptador usa el chip Barrot:

```sh
lsusb | grep -i 33fa
```

Si ves `ID 33fa:0010` (UGREEN BT5.4) o `ID 33fa:0012` (UGREEN BT6.0), este
paquete es para ti. Con el driver normal del kernel, el registro muestra este
bucle cada pocos segundos:

```sh
journalctl -k -b | grep -E '0x2041|UGREEN|USB disconnect'
```

```
Bluetooth: hci0: command 0x2041 tx timeout
usb 1-5: USB disconnect, device number 76
usb 1-5: Product: UGREEN BT5.4 Adapter
```

## 2. Requisitos

**pacman 7.1 o más nuevo:**

```sh
pacman -V
```

**Kernel 6.18 o más nuevo.** El soporte para Barrot apareció en 6.18; los
kernels anteriores se omiten.

```sh
uname -r
```

**Los headers de cada kernel que uses.** Sin ellos, DKMS no puede compilar el
driver para ese kernel:

| Kernel | Paquete de headers |
|---|---|
| `linux` | `linux-headers` |
| `linux-lts` | `linux-lts-headers` |
| `linux-zen` | `linux-zen-headers` |
| `linux-hardened` | `linux-hardened-headers` |
| `linux-cachyos` | `linux-cachyos-headers` |
| `linux-cachyos-lts` | `linux-cachyos-lts-headers` |

Por ejemplo, con el kernel normal de Arch:

```sh
sudo pacman -S --needed base-devel git linux-headers
```

## 3. Instalación

```sh
git clone https://github.com/andrefdev/btusb-barrot-dkms.git
cd btusb-barrot-dkms
makepkg -si
```

Durante la instalación, pacman descarga el código de `btusb` de tu kernel,
lo compila con DKMS para cada kernel con headers (menos de un minuto) y carga
el driver parcheado. No hace falta reiniciar.

> Cuando el paquete esté en el AUR también podrás instalarlo con
> `yay -S btusb-barrot-dkms` o `paru -S btusb-barrot-dkms`.

## 4. Comprobar que funciona

```sh
dkms status btusb-barrot
```

Debe decir `installed` para cada kernel:

```
btusb-barrot/1.3, 7.3.1-1-cachyos, x86_64: installed
```

```sh
sudo dmesg | grep Barrot
```

Debe aparecer `Barrot: hiding LE extended advertising`. Si no aparece,
desconecta y vuelve a conectar el adaptador.

Haz un escaneo BLE, que es justo lo que antes tumbaba el adaptador:

```sh
bluetoothctl --timeout 15 scan on
```

Si aparecen dispositivos y en `journalctl -k -b | grep 0x2041` no hay errores
nuevos, ya está funcionando.

## 5. Emparejar un teclado, ratón o mando BLE

Desde la configuración de Bluetooth de tu escritorio, o con `bluetoothctl` en
modo interactivo:

```
$ bluetoothctl
[bluetoothctl]> scan on
    (pon el dispositivo en modo emparejamiento)
[bluetoothctl]> pair XX:XX:XX:XX:XX:XX
[bluetoothctl]> trust XX:XX:XX:XX:XX:XX
[bluetoothctl]> connect XX:XX:XX:XX:XX:XX
```

Si el dispositivo muestra un código, escríbelo en el dispositivo y pulsa Enter.

Los teclados Logitech cambian de dirección en cada intento de emparejamiento.
Si en la lista ves una entrada antigua que no conecta, bórrala con
`bluetoothctl remove XX:XX:XX:XX:XX:XX` y empareja la nueva.

## 6. Actualizaciones del kernel

No tienes que hacer nada. Al actualizar el kernel verás en pacman:

```
(3/9) Fetching btusb sources for the Barrot Bluetooth patch...
(4/9) Install DKMS modules
==> dkms install --no-depmod btusb-barrot/1.3 -k <nuevo kernel>
(6/9) Checking the Barrot Bluetooth patch (btusb-barrot)...
```

Si algo falla, el paquete lo vuelve a intentar al detectar el adaptador y, si
aun así no puede, te muestra una notificación en el escritorio.

Para actualizar el paquete en sí:

```sh
cd btusb-barrot-dkms
git pull
makepkg -si
```

## 7. Solución de problemas

**El adaptador se sigue desconectando**

```sh
sudo btusb-barrot-fix
modinfo -n btusb
```

La ruta debe contener `updates/dkms`. Si contiene `kernel/drivers`, se está
usando el driver original.

**Ver qué pasó**

```sh
journalctl -u btusb-barrot-autofix.service -b
cat /var/lib/dkms/btusb-barrot/*/$(uname -r)/x86_64/log/make.log
```

**Faltan los headers de un kernel.** Instálalos (tabla de la sección 2) y
ejecuta `sudo btusb-barrot-fix`.

**Secure Boot activado.** El kernel solo carga módulos firmados. Configura la
firma de DKMS (`mok_signing_key` y `mok_certificate` en
`/etc/dkms/framework.conf`) e inscribe la clave con `mokutil --import`.

**`bluetoothctl pair` dice "No agent available".** Usa `bluetoothctl` en modo
interactivo (sección 5) o la configuración de Bluetooth del escritorio.

## 8. Desinstalar

```sh
sudo pacman -R btusb-barrot-dkms
sudo modprobe -r btusb && sudo modprobe btusb
```

Cuando tu kernel incluya el arreglo oficial, pacman te avisará de que ya
puedes desinstalarlo.

## 9. Reportar un problema

Abre un [issue](https://github.com/andrefdev/btusb-barrot-dkms/issues) con la
salida de:

```sh
lsusb | grep -i 33fa
uname -r
dkms status btusb-barrot
journalctl -k -b | grep -iE 'hci0|barrot|33fa|bluetooth' | tail -50
```
