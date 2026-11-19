param(
    [string]$GitDir = (Split-Path $PSScriptRoot -Parent),
    [switch]$Install
)
$ErrorActionPreference = 'Stop'
function Resolve-Directory($path) {
    $item = Get-Item -LiteralPath $path -Force
    if ($item.LinkType -in @('Junction', 'SymbolicLink')) {
        $target = @($item.Target)[0]
        if (![IO.Path]::IsPathRooted($target)) { $target = Join-Path $item.Parent.FullName $target }
        return Resolve-Directory $target
    }
    if (!$item.Parent) { return $item.FullName }
    return Join-Path (Resolve-Directory $item.Parent.FullName) $item.Name
}
$GitDir = Resolve-Directory $GitDir
$root = if ($env:XDG_CONFIG_HOME) { Join-Path $env:XDG_CONFIG_HOME 'skillshare' } else { Join-Path $env:APPDATA 'skillshare' }
$shared = Join-Path $GitDir '.config\skillshare'
$skills = Join-Path $shared 'skills'
$live = Join-Path $root 'skills'
$metadata = Join-Path $skills '.metadata.json'

function Read-Metadata($path) {
    $data = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($data.version -ne 1 -or !$data.entries) { throw "Unsupported skillshare metadata: $path" }
    return $data
}
function Write-Json($path, $data) {
    $temporary = $path + '.' + [guid]::NewGuid().ToString() + '.tmp'
    try {
        [IO.File]::WriteAllText($temporary, (($data | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
        if (Test-Path -LiteralPath $path) { [IO.File]::Replace($temporary, $path, [NullString]::Value) }
        else { [IO.File]::Move($temporary, $path) }
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
    }
}
function Merge-Metadata($existing, $managed) {
    $combined = [ordered]@{}
    foreach ($value in @($existing, $managed)) {
        foreach ($property in $value.PSObject.Properties) { $combined[$property.Name] = $property.Value }
    }
    foreach ($field in @('entries', 'audit_accepted', 'target_overrides')) {
        if ($existing.PSObject.Properties[$field] -or $managed.PSObject.Properties[$field]) {
            $records = [ordered]@{}
            foreach ($value in @($existing.$field, $managed.$field)) {
                if ($null -ne $value) {
                    foreach ($property in $value.PSObject.Properties) { $records[$property.Name] = $property.Value }
                }
            }
            $combined[$field] = $records
        }
    }
    return [pscustomobject]$combined
}
function Copy-Missing($source, $target) {
    foreach ($entry in Get-ChildItem -LiteralPath $source -Force) {
        if ($entry.Name -in @('.metadata.json', '.skillignore')) { continue }
        $destination = Join-Path $target $entry.Name
        if ($entry.PSIsContainer -and !$entry.LinkType) {
            if (!(Test-Path -LiteralPath $destination)) { New-Item -ItemType Directory $destination | Out-Null }
            $current = Get-Item -LiteralPath $destination -Force
            if ($current.PSIsContainer -and !$current.LinkType) { Copy-Missing $entry.FullName $destination }
        } elseif (!(Test-Path -LiteralPath $destination)) {
            if ($entry.LinkType -and $entry.PSIsContainer) {
                New-Item -ItemType Junction -Path $destination -Target @($entry.Target)[0] | Out-Null
            } else { Copy-Item -LiteralPath $entry.FullName -Destination $destination }
        }
    }
}

New-Item -ItemType Directory $root -Force | Out-Null
$managed = Read-Metadata $metadata
$current = Get-Item -LiteralPath $live -Force -ErrorAction SilentlyContinue
if ($current -and $current.LinkType) {
    if ([IO.Path]::GetFullPath(@($current.Target)[0]) -ne [IO.Path]::GetFullPath($skills)) {
        throw "Existing source link points elsewhere: $live"
    }
} else {
    if ($current) {
        $oldMetadata = Join-Path $live '.metadata.json'
        if (Test-Path -LiteralPath $oldMetadata) { Write-Json $metadata (Merge-Metadata (Read-Metadata $oldMetadata) $managed) }
        Copy-Missing $live $skills
        $backup = Join-Path $root ('.dotfiles-backup.' + [guid]::NewGuid())
        New-Item -ItemType Directory $backup | Out-Null
        Move-Item -LiteralPath $live -Destination (Join-Path $backup 'skills')
        Write-Host "backup: $backup"
    }
    New-Item -ItemType Junction -Path $live -Target $skills | Out-Null
}
foreach ($name in @('agents', 'extras', 'ui')) { New-Item -ItemType Directory (Join-Path $root $name) -Force | Out-Null }
foreach ($name in @('manifest.json', 'README.md', 'LICENSE')) {
    Copy-Item "$GitDir\extensions\skillshare-ui-pink-theme\$name" "$root\ui\$name" -Force
}
Copy-Item "$GitDir\.obsidian\plugins\skillshare-ui\theme.css" "$root\ui\theme.css" -Force
Copy-Item "$shared\.skillignore" "$live\.skillignore" -Force
foreach ($name in @('soyomogi', 'trigger')) {
    Copy-Item -LiteralPath (Join-Path "$shared\extras" $name) -Destination "$root\extras" -Recurse -Force
}
$config = Join-Path $root 'config.yaml'
if (!(Test-Path -LiteralPath $config)) {
    Write-Json $config ([ordered]@{
        sources = @{ skills=$live; agents="$root\agents"; extras="$root\extras" }
        mode = 'copy'; follow_source_links = $true
        targets = @{ universal = @{ skills = @{ path="$env:USERPROFILE\.agents\skills"; target_naming='standard' } } }
        extras = @(
            @{name='soyomogi'; file='AGENTS.md'; targets=@(
                @{path="$env:USERPROFILE\.codex"; mode='prepend'}, @{path="$env:USERPROFILE\.agents"; mode='prepend'}
            )}
            @{name='trigger'; file='AGENTS.md'; targets=@(
                @{path="$env:USERPROFILE\.codex"; mode='append'}, @{path="$env:USERPROFILE\.agents"; mode='append'}
            )}
        )
        ignore = @('.DS_Store', '.git/', '__pycache__/'); audit = @{block_threshold='CRITICAL'}
    })
}
if ($Install) {
    $cli = Join-Path $env:LOCALAPPDATA 'Programs\skillshare\skillshare.exe'
    if (!(Test-Path -LiteralPath $cli)) { $cli = (Get-Command skillshare.exe -ErrorAction Stop).Source }
    $previousDebug = $env:GODEBUG
    try {
        $env:GODEBUG = ((@($previousDebug -split ',' | Where-Object { $_ -and $_ -notlike 'winsymlink=*' }) + 'winsymlink=0') -join ',')
        function Invoke-Skillshare {
            & $cli @args
            if ($LASTEXITCODE) { throw "Skillshare failed: $args" }
        }
        $extras = ((Invoke-Skillshare extras list --json -g) -join "`n") | ConvertFrom-Json
        $personal = $extras | Where-Object { $_.name -eq 'soyomogi' -and $_.file -eq 'AGENTS.md' }
        if ($personal -and !($extras | Where-Object { $_.name -eq 'trigger' })) {
            $instructionTargets = @("$env:USERPROFILE\.codex", "$env:USERPROFILE\.agents")
            foreach ($target in $personal.targets) {
                if ($target.path -in $instructionTargets -and $target.mode -ne 'prepend') {
                    Invoke-Skillshare extras soyomogi --target $target.path --mode prepend -g
                }
            }
            # Complete any previous mode transition before registering another writer.
            Invoke-Skillshare sync extras -g
            $triggerArgs = @('extras', 'init', 'trigger', '--file', 'AGENTS.md', '--mode', 'append', '--no-tui', '-g')
            foreach ($target in $instructionTargets) { $triggerArgs += @('--target', $target) }
            Invoke-Skillshare @triggerArgs
        }
        # Read once; install atomically replaces this live, Git-tracked metadata.
        $records = Read-Metadata $metadata
        foreach ($property in $records.entries.PSObject.Properties | Sort-Object Name) {
            $entry = $property.Value
            if (!$entry.repo_url -and !$entry.tracked) { continue }
            $key = $property.Name
            if ($entry.group -and !$key.StartsWith($entry.group + '/')) { $key = $entry.group + '/' + $key }
            $parts = $key -split '/'
            $command = @('install', $entry.source, '--name', $parts[-1], '--update', '-g')
            if ($parts.Count -gt 1) { $command += @('--into', ($parts[0..($parts.Count-2)] -join '/')) }
            if ($entry.tracked) { $command += '--track'; $revision = $entry.branch }
            else { $command += '--all'; $revision = if ($entry.commit) { $entry.commit } else { $entry.branch } }
            if ($revision) { $command += @('--branch', $revision) }
            Invoke-Skillshare @command
        }
        $gitHome = Get-Item (Join-Path $env:USERPROFILE 'git') -Force -ErrorAction SilentlyContinue
        $gitRoot = if ($gitHome.LinkType) { @($gitHome.Target)[0] } else { Join-Path $env:USERPROFILE 'git' }
        $apm = Join-Path $gitRoot 'skills\.agents\skills'
        $link = Join-Path $live '_apm'
        if (Test-Path -LiteralPath $apm) {
            if (!(Test-Path -LiteralPath $link)) { Invoke-Skillshare link $apm --name _apm --enable -g }
            else {
                $item = Get-Item -LiteralPath $link -Force
                if (!$item.LinkType -or [IO.Path]::GetFullPath(@($item.Target)[0]) -ne [IO.Path]::GetFullPath($apm)) {
                    throw "$link already points elsewhere"
                }
            }
        } else { Write-Host 'skip: APM skills are not prepared in ~/git/skills/.agents/skills' }
        Invoke-Skillshare sync -g
        Invoke-Skillshare sync extras -g
    } finally {
        if ($null -eq $previousDebug) { Remove-Item Env:GODEBUG -ErrorAction SilentlyContinue }
        else { $env:GODEBUG = $previousDebug }
    }
}
Write-Host "Windows skillshare source: $live"
