function mkb {
    param (
        [Parameter(Position=0)]
        [string]$Command,

        [Parameter(Position=1)]
        [string[]]$Args
    )

    $validCommands = @("add", "go", "list", "del")

    function Show-Help {
        @"
Usage:
  mkb add <name> [<name2> ...]      Adds bookmark(s) for current directory
  mkb go <name>                     Navigates to the path of the given bookmark
  mkb list                          Lists all bookmarks
  mkb del <name> [<name2> ...]      Deletes the given bookmark(s)
"@ | Write-Host
    }

    if (-not $Command -or $Command -notin $validCommands) {
        Show-Help
        return
    }

    $bookmarkFile = "$env:USERPROFILE\.mkb_bookmarks.json"

    if (-not (Test-Path $bookmarkFile)) {
        @{} | ConvertTo-Json | Set-Content -Path $bookmarkFile
    }

    $json = Get-Content $bookmarkFile | ConvertFrom-Json

    $bookmarks = @{}
    if ($json.psobject.properties.count -gt 0) {
        $json.psobject.properties.name | % { $bookmarks[$_] = $json.$_ }
    }

    switch ($Command) {
        "add" {
            if (-not $Args) {
                Write-Error "No bookmark name provided."
                return
            }
            foreach ($arg in $Args) {
                $bookmarks[$arg] = (Get-Location).Path
                Write-Host "Added bookmark '$arg' -> $($bookmarks[$arg])"
            }
            $bookmarks | ConvertTo-Json | Set-Content -Path $bookmarkFile
        }

        "go" {
            if (-not $Args -or $Args.Count -ne 1) {
                Write-Error "Usage: mkb go <bookmark>"
                return
            }
            $name = $Args[0]
            if ($bookmarks.ContainsKey($name)) {
                Set-Location $bookmarks[$name]
            } else {
                Write-Error "Bookmark '$name' not found."
            }
        }

        "list" {
            $table = $bookmarks.GetEnumerator() | Sort-Object Name | ForEach-Object {
                [PSCustomObject]@{
                    Bookmark = $_.Key
                    Path     = $_.Value
                }
            }
            $table | Format-Table -AutoSize
        }

        "del" {
            if (-not $Args) {
                Write-Error "No bookmark names provided."
                return
            }
            foreach ($arg in $Args) {
                if ($bookmarks.ContainsKey($arg)) {
                    $bookmarks.Remove($arg)
                    Write-Host "Deleted bookmark '$arg'"
                } else {
                    Write-Warning "Bookmark '$arg' not found."
                }
            }
            $bookmarks | ConvertTo-Json | Set-Content -Path $bookmarkFile
        }
    }
}
