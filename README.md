# Windows devbox

UWP stuff nuked with autounattend along with some settings. Rest lies in [debloat script](scripts/debloat.ps1) as reversible.

Autounattend: https://github.com/cschneegans/unattend-generator

## AutoHotkey

[sswm](ahk/sswm.ahk) with VDA for workspaces:

- Replaces <kbd>CapsLock</kbd> with next/prev workspace
- <kbd>#x</kbd> for switches (11th desktop is ignored to drop any long running background tasks <kbd>#^Del</kbd> to focus, <kbd>#^+Del</kbd> to move)
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

## MSYS2 zsh + WindowsTerminal

Dependencies must be from a Cygwin shell instead of WinGet because paths

Run [init script](scripts/init-env.ps1) to import necessary environment vars.

## Relevant Windows settings & categories

- Developer settings
- Automatically hide taskbar
- control > Power Plan > High Performance

## Package manager stuff

```shell
winget source remove msstore
```

```shell
winget install altsnap autohotkey microsoft.visualstudio.community microsoft.windowsterminal msys2.msys2 systeminformer voidtools.everything.alpha vscodium
```

```shell
pacman -S $MINGW_PACKAGE_PREFIX-fd $MINGW_PACKAGE_PREFIX-fzf $MINGW_PACKAGE_PREFIX-magick $MINGW_PACKAGE_PREFIX-mpv $MINGW_PACKAGE_PREFIX-starship $MINGW_PACKAGE_PREFIX-ripgrep $MINGW_PACKAGE_PREFIX-zoxide
```
