. "$HOME\.config\alias\git-commandes\docs.ps1"


# Description
# This function displays help information for Git.
# You can either view general Git help or get help for a specific command.

# Usage
# gHelp        → Show general Git help
# gHelp commit → Show help for a specific Git command (e.g. commit, push, etc.)
function gHelp {
    param([string]$cmd)
    if ($cmd) {  help $cmd } else { git help }
}


# Description
# This function allows you to manage Git configuration easily using simplified aliases.
# It supports setting, getting, and listing Git config values at different levels:
# global, local, or system.

# Usage
# gConfig                     → List all config values (default scope: global)
# gConfig name               → Get the value of a config field
# gConfig name "value"       → Set a config field
# gConfig name "value" -g    → Set global config (default)
# gConfig name "value" -l    → Set local repository config
# gConfig name "value" -s    → Set system-wide config
function gConfig {
    param(
        [Parameter(Position=0)]
        [ValidateSet("name","email","editor","ui","autocrlf","defaultbranch","pager","merge","rebase","credentialhelper","signingkey")]
        [string]$field,

        [Parameter(Position=1)]
        [string]$value,

        [switch]$g,
        [switch]$l,
        [switch]$s
    )

    $level = "global"
    if ($l) { $level = "local" }
    elseif ($s) { $level = "system" }
    elseif ($g) { $level = "global" }

    $map = @{
        name             = "user.name"
        email            = "user.email"
        editor           = "core.editor"
        ui               = "color.ui"
        autocrlf         = "core.autocrlf"
        defaultbranch    = "init.defaultBranch"
        pager            = "core.pager"
        merge            = "merge.tool"
        rebase           = "pull.rebase"
        credentialhelper = "credential.helper"
        signingkey       = "user.signingkey"
    }

    if (-not $field -and -not $value) {
        git config --$level --list
        return
    }

    $key = $map[$field]

    if (-not $key) {
        Write-Host "❌ Unsupported field"
        return
    }

    if ($field -and -not $value) {
        git config --$level --get $key
        return
    }

    if ($field -and $value) {
        git config --$level $key $value
        Write-Host "✅ ($level) $key = $value"
        return
    }
}

