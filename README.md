# Windows devbox

UWP stuff nuked with autounattend along with some settings. Rest lies in [debloat script](scripts/debloat.ps1) as reversible.

Autounattend: https://github.com/cschneegans/unattend-generator

## AutoHotkey

[sswm](ahk/sswm.ahk) with VDA for workspaces:
- Replaces CapsLock with next/prev workspace
- <kbd>#x</kbd> for switches (11th desktop is ignored to drop any long running background tasks #^Del to focus, <kbd>#^+Del</kbd> to move)
- <kbd>#CapsLock</kbd>, <kbd>#F1-4</kbd> (hjkl) to focus to windows (works fine for a quad setup, anything else is out of scope and may be undeterministic) 
- <kbd>#!CapsLock</kbd> to reinit workspace window cache
- <kbd>#F5</kbd> to pin a window across workspaces
- <kbd>#F6</kbd> to toggle pierce-through (click-through) style on focused window, <kbd>#+F6</kbd> to revert all tracked
- <kbd>#F7</kbd> to toggle removing focused window from Alt+Tab, <kbd>#+F7</kbd> to revert all tracked

[shortcuts](ahk/shortcuts.ahk):
- Simple kill keys
- Everything integration, super key suppress

AltSnap: https://github.com/RamonUnch/AltSnap

Everything: https://www.voidtools.com/

VDA: https://github.com/Ciantic/VirtualDesktopAccessor

## MSYS2 zsh + WindowsTerminal

Dependencies must be from a Cygwin shell instead of WinGet because paths

Run [init script](scripts/init-env.ps1) to import necessary environment vars.

## Relevant Windows settings & categories

- Developer settings
- control > Power Plan > High Performance

## WinGet IDs

`winget source remove msstore`

`winget install altsnap autohotkey burntsushi.ripgrep.msvc fd microsoft.windowsterminal msys2.msys2 systeminformer voidtools.everything.alpha vscodium`
