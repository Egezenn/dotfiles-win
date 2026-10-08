# Windows devbox

UWP stuff nuked with autounattend along with some settings. Rest lies in [debloat script](scripts/debloat.ps1) as reversible.

Autounattend: https://github.com/cschneegans/unattend-generator

## AutoHotkey

[sswm](ahk/sswm.ahk) with VDA for workspaces:

- Replaces <kbd>CapsLock</kbd> with next/prev workspace
- <kbd>#0-9</kbd> for switches (11th desktop is ignored to drop any long running background tasks <kbd>#^Del</kbd> to focus, <kbd>#^+Del</kbd> to move)
- <kbd>#CapsLock</kbd>, <kbd>#F1-4</kbd> (hjkl) to focus to windows (works fine for a quad setup, anything else is out of scope and may be undeterministic)
- <kbd>#!CapsLock</kbd> to reinit workspace window cache
- <kbd>#F5</kbd> to pin a window across workspaces
- <kbd>#F6</kbd> to toggle pierce-through (click-through) style on focused window, <kbd>#+F6</kbd> to revert all tracked
- <kbd>#F7</kbd> to toggle removing focused window from Alt+Tab, <kbd>#+F7</kbd> to revert all tracked
- <kbd>#F9</kbd> kill monitor output

[shortcuts](ahk/shortcuts.ahk):

- Simple kill keys
- Everything integration, super key suppress
- Transparency & zoom controls with mouse wheel

AltSnap: https://github.com/RamonUnch/AltSnap

Everything: https://www.voidtools.com/

VDA: https://github.com/Ciantic/VirtualDesktopAccessor

Explorer++: https://github.com/derceg/explorerplusplus [\*](https://github.com/derceg/explorerplusplus/actions/workflows/build.yml)

MPD: https://www.musicpd.org/download.html

## Relevant Windows settings & categories

- Developer settings
- Automatically hide taskbar
- control > Power Plan > High Performance

## Package manager stuff

```shell
winget source remove msstore
```

```shell
winget install `
  AltSnap `
  astral-sh.uv `
  AutoHotkey `
  Microsoft.Coreutils `
  Microsoft.VCRedist.2015+.x64 `
  Microsoft.WindowsTerminal `
  MSYS2.MSYS2 `
  Nub.Nub `
  OpenJS.NodeJS `
  SystemInformer `
  voidtools.Everything.Alpha `
  VSCodium
```

```shell
pacman -S \
  zsh \
  $MINGW_PACKAGE_PREFIX-fd \
  $MINGW_PACKAGE_PREFIX-fzf \
  $MINGW_PACKAGE_PREFIX-lsd \
  $MINGW_PACKAGE_PREFIX-imagemagick \
  $MINGW_PACKAGE_PREFIX-mpv \
  $MINGW_PACKAGE_PREFIX-ripgrep \
  $MINGW_PACKAGE_PREFIX-starship \
  $MINGW_PACKAGE_PREFIX-ttf-font-nerd \
  $MINGW_PACKAGE_PREFIX-zoxide
```
