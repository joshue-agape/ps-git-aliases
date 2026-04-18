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


# Description
# This function initializes a new Git repository.
# Optionally, it can also stage all files and create an initial commit.

# Usage
# gInit        → Initialize a Git repository only
# gInit -c     → Initialize repository, add all files, and commit
# gInit -c "message" → Initialize + add + commit with custom message
function gInit {
    param(
        [switch]$c,
        [string]$message = "Initial commit"
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Git is not installed or not available in PATH"
        return
    }

    git init

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to initialize Git repository"
        return
    }

    if ($c) {
        git add .

        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to stage files (git add)"
            return
        }

        git commit -m "$message"

        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Failed to create commit"
            return
        }

        Write-Host "✅ Repository initialized and committed: $message"
    } else {
        Write-Host "✅ Repository initialized successfully"
    }
}


# Description
# This function provides an enhanced Git clone command.
# It supports optional branch selection and target folder naming.

# Usage
# gClone <url>
# gClone <url> <folder>
# gClone <branch> <url> <folder>
function gClone {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$arg1,

        [Parameter(Position=1)]
        [string]$arg2,

        [Parameter(Position=2)]
        [string]$arg3
    )

    $branch = $null
    $url    = $null
    $folder = $null

    $isUrl1 = $arg1 -match '^(https?://|git@|ssh://|[\w.-]+@[\w.-]+:)'

    if ($isUrl1) {
        $url    = $arg1
        $folder = $arg2
    }
    else {
        $branch = $arg1
        $url    = $arg2
        $folder = $arg3
    }

    if (-not $url) {
        Write-Host "❌ Invalid usage:"
        Write-Host "  gClone <url>"
        Write-Host "  gClone <url> [folder]"
        Write-Host "  gClone <branch> <url> [folder]"
        return
    }

    $gitArgs = @("clone")

    if ($branch) {
        $gitArgs += @("-b", $branch)
    }

    $gitArgs += $url

    if ($folder) {
        $gitArgs += $folder
    }

    try {
        git @gitArgs
        Write-Host "✅ Repository cloned successfully"
    }
    catch {
        Write-Host "❌ Failed to clone repository"
    }
}


# Description
# This function displays the current Git repository status.

# Usage
# gStatus → Show Git status
function gStatus {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Git is not installed or not available in PATH"
        return
    }

    try {
        git status
    }
    catch {
        Write-Host "❌ Failed to execute git status"
    }
}


# Description
# This function stages files in the Git repository.
# If no file is specified, it stages all changes.

# Usage
# gAdd        → Stage all files
# gAdd file   → Stage a specific file
function gAdd {
    param([string]$file)

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Git is not installed or not available in PATH"
        return
    }

    $target = if ($file) { $file } else { "." }

    try {
        git add $target
        Write-Host "✅ Successfully added: $target"
    }
    catch {
        Write-Host "❌ Failed to add files: $target"
    }
}


# Description
# This function removes a file from the Git repository.
# It uses `git rm` to delete the file and track the change.

# Usage
# gRemove <file> → Remove a file from Git
function gRemove {
    param([string]$file)

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Git is not installed or not available in PATH"
        return
    }

    if (-not $file) {
        Write-Host "Usage: gRemove <file>"
        return
    }

    try {
        git rm $file
        Write-Host "✅ File removed: $file"
    }
    catch {
        Write-Host "❌ Failed to remove file: $file"
    }
}


# Description
# This function moves or renames a file inside a Git repository.
# It uses `git mv` to ensure Git tracks the change properly.

# Usage
# gMove <old> <new> → Move or rename a file
function gMove {
    param([string]$old, [string]$new)

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Git is not installed or not available in PATH"
        return
    }

    if (-not $old -or -not $new) {
        Write-Host "Usage: gMove <old> <new>"
        return
    }

    try {
        git mv $old $new
        Write-Host "✅ File moved: $old → $new"
    }
    catch {
        Write-Host "❌ Failed to move file: $old → $new"
    }
}


# Description
# This function creates Git commits with different options:
# - Normal commit
# - Commit with all tracked changes (-a)
# - Amend last commit (--amend)

# Usage
# gCommit <message>           → Normal commit
# gCommit -a <message>        → Commit all tracked changes
# gCommit --amend <message>   → Amend last commit
function gCommit {
    param(
        [ValidateSet("-a","-u","--amend")]
        [string]$type,

        [Parameter(Mandatory=$true, Position=0)]
        [string]$message
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Git is not installed or not available in PATH"
        return
    }

    if (-not $message) {
        Write-Host "Usage: gCommit [-a|-u|--amend] <message>"
        return
    }

    try {
        switch ($type) {
            "-a"      { git commit -a -m "$message" }
            "-u"      { git commit --amend -m "$message" }
            "--amend" { git commit --amend -m "$message" }
            default   { git commit -m "$message" }
        }

        Write-Host "✅ Commit created: $message"
    }
    catch {
        Write-Host "❌ Failed to create commit"
    }
}


# Description
# This function manages Git branches:
# - Create a branch
# - Delete a branch (-d or -D)
# - List all branches if no argument is provided

# Usage
# gBranch              → List branches
# gBranch <name>       → Create branch
# gBranch -d <name>    → Delete branch (safe)
# gBranch -D <name>    → Force delete branch
function gBranch {
    param(
        [ValidateSet("-d","-D")]
        [string]$type,

        [string]$branch_name
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Git is not installed or not available in PATH"
        return
    }

    try {
        if (-not $branch_name) {
            git branch
            return
        }

        switch ($type) {
            "-d" {
                git branch -d $branch_name
                Write-Host "✅ Branch deleted: $branch_name"
            }
            "-D" {
                git branch -D $branch_name
                Write-Host "✅ Branch force deleted: $branch_name"
            }
            default {
                git branch $branch_name
                Write-Host "✅ Branch created: $branch_name"
            }
        }
    }
    catch {
        Write-Host "❌ Error with branch: $branch_name"
    }
}


# Description
# This function checks out a Git branch.
# It can also create and switch to a new branch if -b is used.

# Usage
# gCheck <branch>        → Switch to existing branch
# gCheck -b <branch>     → Create and switch to new branch
function gCheck {
    param(
        [switch]$b,
        [Parameter(Mandatory=$true)]
        [string]$branch_name
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Git is not installed"
        return
    }

    try {
        if ($b) {
            git checkout -b $branch_name
            Write-Host "✅ Branch created and switched: $branch_name"
        }
        else {
            git checkout $branch_name
            Write-Host "✅ Switched to branch: $branch_name"
        }
    }
    catch {
        Write-Host "❌ Failed to checkout branch: $branch_name"
    }
}


# Description
# This function switches between Git branches using 'git switch'.

# Usage
# gSwitch <branch> → Switch to a branch
function gSwitch {
    param(
        [Parameter(Mandatory=$true)]
        [string]$branch_name
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Git is not installed"
        return
    }

    if (-not $branch_name) {
        Write-Host "Usage: gSwitch <branch_name>"
        return
    }

    try {
        git switch $branch_name
        Write-Host "✅ Switched to branch: $branch_name"
    }
    catch {
        Write-Host "❌ Failed to switch to branch: $branch_name"
    }
}


# Description
# This function merges a Git branch into the current branch.

# Usage
# gMerge <branch> → Merge specified branch into current branch
function gMerge {
    param(
        [Parameter(Mandatory=$true)]
        [string]$branch_name
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Git is not installed or not available in PATH"
        return
    }

    if (-not $branch_name) {
        Write-Host "Usage: gMerge <branch_name>"
        return
    }

    try {
        git merge $branch_name
        Write-Host "✅ Merge completed: $branch_name"
    }
    catch {
        Write-Host "❌ Merge failed: $branch_name"
    }
}