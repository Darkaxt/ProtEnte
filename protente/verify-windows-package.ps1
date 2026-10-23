param(
    [Parameter(Mandatory = $true)][string] $ArtifactDirectory,
    [switch] $SmokeTest
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path -LiteralPath $ArtifactDirectory).Path
$manifest = Get-Content -Raw (Join-Path $root 'release-manifest.json') | ConvertFrom-Json
$stem = "ProtEnte-$($manifest.version)-windows-x64"
foreach ($line in Get-Content (Join-Path $root 'SHA256SUMS')) {
    if ($line -notmatch '^([0-9a-f]{64})  ([A-Za-z0-9.+_-]+)$') { throw "Invalid checksum entry: $line" }
    $expected = $Matches[1]
    $file = Join-Path $root $Matches[2]
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash.ToLowerInvariant() -ne $expected) { throw "Checksum mismatch: $file" }
}
$extracted = Join-Path $root 'verification-extracted'
if (Test-Path -LiteralPath $extracted) { throw "Verification directory already exists: $extracted" }
Expand-Archive -LiteralPath (Join-Path $root "$stem.zip") -DestinationPath $extracted
$bundle = Join-Path $extracted $stem
$exe = Join-Path $bundle $manifest.executable
$info = (Get-Item -LiteralPath $exe).VersionInfo
if ($info.ProductName -ne 'ProtEnte' -or $info.CompanyName -ne 'Darkaxt' -or $info.OriginalFilename -ne 'protente.exe') { throw 'Incorrect packaged executable identity.' }
$version = [Version]$manifest.version
if ($info.FileMajorPart -ne $version.Major -or $info.FileMinorPart -ne $version.Minor -or $info.FileBuildPart -ne $version.Build -or $info.FilePrivatePart -ne $manifest.buildNumber) { throw 'Incorrect packaged file version.' }
$pluginBytes = [IO.File]::ReadAllBytes((Join-Path $bundle 'flutter_secure_storage_windows_plugin.dll'))
$pluginText = [Text.Encoding]::ASCII.GetString($pluginBytes)
if (-not $pluginText.Contains('protente_VGhpcyBpcyB0aGUgcHJlZml4IGZv_')) { throw 'Credential namespace not found in packaged storage plugin.' }
$inner = Get-Content -Raw (Join-Path $bundle 'release-manifest.json') | ConvertFrom-Json
if ($inner.sourceRevision -ne $manifest.sourceRevision) { throw 'Inner and outer source identities differ.' }
foreach ($required in @('LICENSE','BASELINE-NOTICE.txt','flutter_windows.dll','data/flutter_assets/AssetManifest.bin','data/app.so')) {
    if (-not (Test-Path -LiteralPath (Join-Path $bundle $required))) { throw "Missing packaged file: $required" }
}
$signature = Get-AuthenticodeSignature -LiteralPath $exe
if ($signature.Status -ne 'NotSigned') { throw "Review unexpected Authenticode status: $($signature.Status)" }
$verification = [ordered]@{
    sourceRevision = $manifest.sourceRevision
    version = $manifest.version
    checksumsVerified = $true
    executableIdentityVerified = $true
    credentialNamespaceVerified = $true
    authenticode = [string]$signature.Status
    installerRoundTripVerified = $false
    nativeWindowStartupVerified = $false
    renderedFlutterUiVerified = $false
    realAccountOrVaultUsed = $false
}
if ($SmokeTest) {
    if ($env:GITHUB_ACTIONS -ne 'true' -or -not $env:RUNNER_TEMP) { throw 'Installation smoke test is restricted to disposable GitHub runners.' }
    $install = Join-Path $env:RUNNER_TEMP 'ProtEnte-smoke-install'
    if (Test-Path -LiteralPath $install) { throw 'Smoke installation already exists.' }
    $upstreamProtocol = 'Registry::HKEY_CURRENT_USER/Software/Classes/enteauth/shell/open/command'
    $previousUpstream = if (Test-Path $upstreamProtocol) { (Get-Item $upstreamProtocol).GetValue('') } else { $null }
    $installer = Start-Process -FilePath (Join-Path $root "$stem-installer.exe") -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',"/DIR=`"$install`"") -Wait -PassThru
    if ($installer.ExitCode -ne 0) { throw "Installer failed: $($installer.ExitCode)" }
    $installedExe = Join-Path $install 'protente.exe'
    if ((Get-FileHash $installedExe).Hash -ne (Get-FileHash $exe).Hash) { throw 'Installed executable differs from ZIP.' }
    $protocol = (Get-Item 'Registry::HKEY_CURRENT_USER/Software/Classes/protente/shell/open/command').GetValue('')
    if ($protocol -ne "`"$installedExe`" `"%1`"") { throw "Incorrect URL handler: $protocol" }
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class ProtEnteSmokeWindow {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string name, string title);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool PostThreadMessage(uint id, uint message, UIntPtr wParam, IntPtr lParam);
}
'@
    $process = Start-Process -FilePath $installedExe -WindowStyle Hidden -PassThru
    try {
        if (-not $process.WaitForInputIdle()) { throw 'Application did not reach its native input loop.' }
        $window = [ProtEnteSmokeWindow]::FindWindow('FLUTTER_RUNNER_WIN32_WINDOW','ProtEnte')
        [uint32]$windowProcess = 0
        $thread = [ProtEnteSmokeWindow]::GetWindowThreadProcessId($window, [ref]$windowProcess)
        if ($window -eq [IntPtr]::Zero -or $windowProcess -ne $process.Id) { throw 'The test process did not create the ProtEnte window.' }
        $verification.nativeWindowStartupVerified = $true
        if (-not [ProtEnteSmokeWindow]::PostThreadMessage($thread, 0x0012, [UIntPtr]::Zero, [IntPtr]::Zero)) { throw 'Could not request native loop shutdown.' }
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) { throw "Application exited abnormally: $($process.ExitCode)" }
    } finally { $process.Dispose() }
    $currentUpstream = if (Test-Path $upstreamProtocol) { (Get-Item $upstreamProtocol).GetValue('') } else { $null }
    if ($currentUpstream -ne $previousUpstream) { throw 'Upstream Ente URL handler changed.' }
    $uninstaller = Start-Process -FilePath (Join-Path $install 'unins000.exe') -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART') -Wait -PassThru
    if ($uninstaller.ExitCode -ne 0 -or (Test-Path -LiteralPath $installedExe)) { throw 'Uninstall did not remove the application.' }
    $verification.installerRoundTripVerified = $true
}
$verification | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $root 'package-verification.json')
$verification | ConvertTo-Json
