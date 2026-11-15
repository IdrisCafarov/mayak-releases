# Mayak installer for Windows (per-user, no admin needed).
# Downloads the latest release from GitHub over HTTPS, verifies its SHA-256 checksum, runs the installer.
$ErrorActionPreference = "Stop"
$Repo = "IdrisCafarov/mayak-releases"
Write-Host "Finding the latest Mayak release..."
$rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ "User-Agent" = "mayak-installer" }
$asset = $rel.assets | Where-Object { $_.name -like "*_x64-setup.exe" } | Select-Object -First 1
$sums = $rel.assets | Where-Object { $_.name -eq "SHA256SUMS.txt" } | Select-Object -First 1
if (-not $asset -or -not $sums) { throw "This release is missing the Windows installer or its checksum file." }
if (-not $asset.browser_download_url.StartsWith("https://github.com/$Repo/releases/download/")) { throw "Unexpected download URL." }

$tmp = Join-Path $env:TEMP ("mayak-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null
$exe = Join-Path $tmp $asset.name
Write-Host "Downloading $($asset.name)..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $exe -UseBasicParsing
$sumText = (Invoke-WebRequest -Uri $sums.browser_download_url -UseBasicParsing).Content
$expected = ($sumText -split "`n" | Where-Object { $_ -match [regex]::Escape($asset.name) + '\s*$' } | ForEach-Object { ($_ -split '\s+')[0] }) | Select-Object -First 1
$actual = (Get-FileHash -Algorithm SHA256 $exe).Hash.ToLower()
if (-not $expected -or $expected.ToLower() -ne $actual) { Remove-Item -Recurse -Force $tmp; throw "Checksum mismatch! Not installing." }
Write-Host "Checksum OK. Starting the installer..."
Start-Process -FilePath $exe -Wait
Remove-Item -Recurse -Force $tmp
Write-Host "Done. Mayak is in your Start menu."
