function refreshenv {
    foreach ($level in "Machine", "User") {
        [System.Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
            Set-Item -Path "Env:$($_.Key)" -Value $_.Value
        }
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host "Environment variables refreshed." -ForegroundColor Green
}

$env:STARSHIP_CONFIG = "$env:USERPROFILE\.config\loose\starship.toml"
starship init powershell --print-full-init | Out-String | Invoke-Expression
zoxide init powershell | Out-String | Invoke-Expression

$env:FZF_DEFAULT_OPTS = "--color=bg+:#252526,bg:#1e1e1e,spinner:#007acc,hl:#3794ff --color=fg:#cccccc,header:#007acc,info:#858585,pointer:#007acc --color=marker:#4ec9b0,fg+:#ffffff,prompt:#3794ff,hl+:#75beff --height=40% --layout=reverse --border --prompt='󰭎 ' --pointer='▶' --marker='✓'"
$env:FZF_DEFAULT_COMMAND = 'fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
$env:FZF_CTRL_T_COMMAND = $env:FZF_DEFAULT_COMMAND
$env:FZF_ALT_C_COMMAND = 'fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'

Import-Module PSReadLine -MinimumVersion 2.0.0

Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -MaximumHistoryCount 10000
Set-PSReadLineOption -HistoryNoDuplicates

try {
    Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
    Set-PSReadLineOption -PredictionViewStyle InlineView
    Set-PSReadLineOption -Colors @{
        InlinePrediction = "`e[38;2;106;115;125m"
    }
} catch {}

Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Word navigation
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Alt+b' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord

# Suggestions / Completion
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord 'Ctrl+Spacebar' -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Chord 'Alt+f' -Function AcceptNextSuggestionWord
Set-PSReadLineKeyHandler -Chord 'Alt+RightArrow' -Function AcceptNextSuggestionWord

# Word / Line deletion
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardKillWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+Backspace' -Function BackwardKillWord
Set-PSReadLineKeyHandler -Chord 'Alt+Backspace' -Function BackwardKillWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function KillWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+Delete' -Function KillWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+u' -Function BackwardKillLine
Set-PSReadLineKeyHandler -Chord 'Ctrl+k' -Function KillLine

Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Shift+Tab' -Function MenuComplete

Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -BriefDescription 'FZF History' -ScriptBlock {
    $histPath = (Get-PSReadLineOption).HistorySavePath
    $selected = Get-Content $histPath -Encoding utf8 -ErrorAction SilentlyContinue |
        Select-Object -Unique |
        & fzf --tac --tiebreak=index --no-sort --prompt='󰭎 History: '
    if ($selected) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected)
    }
}

Set-PSReadLineKeyHandler -Chord 'Ctrl+t' -BriefDescription 'FZF File Search' -ScriptBlock {
    $selected = Invoke-Expression $env:FZF_CTRL_T_COMMAND | & fzf -m --prompt='󰭎 Files: '
    if ($selected) {
        $formatted = ($selected | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join ' '
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($formatted)
    }
}

Set-PSReadLineKeyHandler -Chord 'Alt+c' -BriefDescription 'FZF Directory Jump' -ScriptBlock {
    $selected = Invoke-Expression $env:FZF_ALT_C_COMMAND | & fzf --prompt='󰭎 Dir: '
    if ($selected) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("Set-Location `"$selected`"")
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}

Remove-Item Alias:cp, Alias:mv, Alias:rm, Alias:rmdir, Alias:cat, Alias:diff, Alias:ls, Alias:curl, Alias:wget, Alias:sleep, Alias:tee, Alias:sort -Force -ErrorAction SilentlyContinue

function ls   { & lsd --group-directories-first @args }
function l    { & lsd -l --group-directories-first @args }
function la   { & lsd -a --group-directories-first @args }
function ll   { & lsd -la --group-directories-first @args }
function lt   { & lsd --tree --depth=2 @args }
function tree { & lsd --tree @args }

function ..   { Set-Location .. }
function ...  { Set-Location ../.. }
function .... { Set-Location ../../.. }

function c      { Clear-Host }
function reload { . $PROFILE; Write-Host "󰑓 PowerShell configuration reloaded!" -ForegroundColor Cyan }
function which ($name) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) {
        if ($cmd.Source) {
            $cmd.Source
        } elseif ($cmd.ResolvedCommand) {
            $target = if ($cmd.ResolvedCommand.Source) { $cmd.ResolvedCommand.Source } else { $cmd.ResolvedCommand.Name }
            "{0} -> {1}" -f $cmd.Name, $target
        } else {
            "{0} ({1})" -f $cmd.Name, $cmd.CommandType
        }
    }
}

. "$env:USERPROFILE\.config\pwsh\oddities.ps1"
