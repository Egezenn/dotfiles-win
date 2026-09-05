# Windows devbox

UWP stuff nuked with autounattend along with some settings. Rest lies in [debloat script](scripts/debloat.ps1) as reversible.

Autounattend: https://github.com/cschneegans/unattend-generator

## AutoHotkey

[sswm](ahk/sswm.ahk) with VDA for workspaces:
- Replaces CapsLock with next/prev workspace
- #x for switches (11th desktop is ignored to drop any long running background tasks #^Del to focus, #^+Del to move)
- #CapsLock, #F1-4 (hjkl) to focus to windows (works fine for a quad setup, anything else is out of scope and may be undeterministic) 
- #!CapsLock to reinit workspace window cache
- #F5 to pin a window across workspaces
- #F6 to toggle pierce-through (click-through) style on focused window, #+F6 to revert all tracked
- #F7 to toggle removing focused window from Alt+Tab, #+F7 to revert all tracked

[shortcuts](ahk/shortcuts.ahk):
- Simple kill keys
- Everything integration, super key suppress

AltSnap: https://github.com/RamonUnch/AltSnap
Everything: https://www.voidtools.com/
VDA: https://github.com/Ciantic/VirtualDesktopAccessor

## MSYS2 zsh + WindowsTerminal

Dependencies must be from a Cygwin shell instead of WinGet because paths

`C:/msys64/msys2_shell.cmd`

```bat
set MSYS=winsymlinks:nativestrict
set MSYS2_PATH_TYPE=inherit
set "LOGINSHELL=zsh"
```

## Relevant Windows settings & categories

- Developer settings
- control > Power Plan > High Performance

## WinGet IDs

`winget source remove msstore`

`winget install altsnap autohotkey burntsushi.ripgrep.msvc fd microsoft.windowsterminal msys2.msys2 systeminformer voidtools.everything.alpha vscodium`
