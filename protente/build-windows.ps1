param(
    [Parameter(Mandatory = $true)][string] $OutputDirectory,
    [string] $Flutter = 'flutter',
    [string] $IsccPath
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not $IsWindows) { throw 'Build on Windows with Visual Studio 2022 C++ desktop tools.' }
$root = Split-Path -Parent $PSScriptRoot
$metadata = Get-Content -Raw (Join-Path $PSScriptRoot 'windows.json') | ConvertFrom-Json
$output = [IO.Path]::GetFullPath($OutputDirectory)
if ((Test-Path -LiteralPath $output) -and (Get-ChildItem -LiteralPath $output -Force)) { throw "Use an empty output directory: $output" }
New-Item -ItemType Directory -Force -Path $output | Out-Null
& $Flutter --version
if ($LASTEXITCODE -ne 0) { throw 'Flutter tool initialization failed.' }
$flutterInfo = (& $Flutter --version --machine | ConvertFrom-Json)
if ($LASTEXITCODE -ne 0 -or $flutterInfo.frameworkVersion -ne $metadata.flutterVersion) { throw "Flutter $($metadata.flutterVersion) is required." }
$sourceRevision = git -C $root rev-parse HEAD
if ($LASTEXITCODE -ne 0) { throw 'Cannot identify source revision.' }
$stem = "ProtEnte-$($metadata.version)-windows-x64"
Push-Location (Join-Path $root 'mobile/apps/auth')
try {
    & $Flutter pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    & $Flutter test --no-pub test/protente_windows_baseline_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'Windows isolation checks failed.' }
    & $Flutter analyze --no-pub lib/app/view/app.dart lib/core/configuration.dart lib/main.dart lib/services/update_service.dart lib/utils/directory_utils.dart lib/utils/window_protocol_handler.dart lib/ui/settings/about_settings_page.dart lib/ui/home_page.dart lib/onboarding/view/onboarding_page.dart test/protente_windows_baseline_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'Analysis failed.' }
    & $Flutter build windows --release --no-pub "--build-name=$($metadata.version)" "--build-number=$($metadata.buildNumber)"
    if ($LASTEXITCODE -ne 0) { throw 'Windows Release build failed.' }
    $payload = [IO.Path]::GetFullPath('build/windows/x64/runner/Release')
    & ./scripts/verify_windows_pe_allowlist.ps1 -PayloadDir $payload -AllowlistPath windows/signing/allowed-pe-files.txt
    if ($LASTEXITCODE -ne 0) { throw 'Unexpected Windows payload.' }
    $versionInfo = (Get-Item (Join-Path $payload $metadata.executable)).VersionInfo
    if ($versionInfo.ProductName -ne $metadata.name -or $versionInfo.CompanyName -ne $metadata.publisher -or $versionInfo.ProductVersion -ne "$($metadata.version)+$($metadata.buildNumber)") { throw "Incorrect executable identity/version: $($versionInfo | Out-String)" }
    $bundle = Join-Path $output $stem
    Copy-Item -LiteralPath $payload -Destination $bundle -Recurse
    Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $bundle 'LICENSE')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'BASELINE-NOTICE.txt') -Destination $bundle
    $manifest = [ordered]@{}
    $metadata.PSObject.Properties | ForEach-Object { $manifest[$_.Name] = $_.Value }
    $manifest.sourceRevision = $sourceRevision.Trim()
    $manifest.flutterRevision = $flutterInfo.frameworkRevision
    $manifest.buildConfiguration = 'Release'
    $manifest.architecture = 'x64'
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $output 'release-manifest.json')
    Copy-Item -LiteralPath (Join-Path $output 'release-manifest.json') -Destination $bundle
    & "$PSScriptRoot/build-installer.ps1" -SourceDir $bundle -InstallerPath (Join-Path $output "$stem-installer.exe") -IsccPath $IsccPath
    Compress-Archive -LiteralPath $bundle -DestinationPath (Join-Path $output "$stem.zip") -CompressionLevel Optimal
    $checksums = foreach ($file in @("$stem-installer.exe", "$stem.zip", 'release-manifest.json')) {
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $output $file)).Hash.ToLowerInvariant()
        "$hash  $file"
    }
    $checksums | Set-Content -Encoding ascii (Join-Path $output 'SHA256SUMS')
    Write-Host "Packaged unsigned ProtEnte $($metadata.version) from $sourceRevision in $output"
} finally { Pop-Location }
