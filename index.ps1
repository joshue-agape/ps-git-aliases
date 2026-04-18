. "$HOME\.config\alias\git-commandes\docs.ps1"


function gHelp {
    param([string]$cmd)
    if ($cmd) {  help $cmd } else { git help }
}
