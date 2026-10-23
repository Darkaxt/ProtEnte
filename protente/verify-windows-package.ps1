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
$installerSignature = Get-AuthenticodeSignature -LiteralPath (Join-Path $root "$stem-installer.exe")
if ($signature.Status -ne 'NotSigned' -or $installerSignature.Status -ne 'NotSigned') { throw 'Review unexpected Authenticode status.' }
$verification = [ordered]@{
    sourceRevision = $manifest.sourceRevision
    version = $manifest.version
    checksumsVerified = $true
    executableIdentityVerified = $true
    credentialNamespaceVerified = $true
    authenticode = [string]$signature.Status
    installerAuthenticode = [string]$installerSignature.Status
    installerRoundTripVerified = $false
    nativeWindowStartupVerified = $false
    renderedFlutterUiVerified = $false
    realAccountOrVaultUsed = $false
}
if ($SmokeTest) {
    if ($env:GITHUB_ACTIONS -ne 'true' -or -not $env:RUNNER_TEMP) { throw 'Installation smoke test is restricted to disposable GitHub runners.' }
    $install = Join-Path $env:RUNNER_TEMP 'ProtEnte-smoke-install'
    if (Test-Path -LiteralPath $install) { throw 'Smoke installation already exists.' }
    $upstreamProtocol = 'Registry::HKEY_CURRENT_USER\Software\Classes\enteauth\shell\open\command'
    $previousUpstream = if (Test-Path $upstreamProtocol) { (Get-Item $upstreamProtocol).GetValue('') } else { $null }
    $installer = Start-Process -FilePath (Join-Path $root "$stem-installer.exe") -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',"/DIR=`"$install`"") -Wait -PassThru
    if ($installer.ExitCode -ne 0) { throw "Installer failed: $($installer.ExitCode)" }
    $installedExe = Join-Path $install 'protente.exe'
    if ((Get-FileHash $installedExe).Hash -ne (Get-FileHash $exe).Hash) { throw 'Installed executable differs from ZIP.' }
    $protocol = (Get-Item 'Registry::HKEY_CURRENT_USER\Software\Classes\protente\shell\open\command').GetValue('')
    if ($protocol -ne "`"$installedExe`" `"%1`"") { throw "Incorrect URL handler: $protocol" }
    Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class ProtEnteSmokeWindow {
    delegate void WinEventProc(IntPtr hook, uint evt, IntPtr hwnd, int obj, int child, uint thread, uint time);
    [StructLayout(LayoutKind.Sequential)] struct Point { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] struct Message { public IntPtr Hwnd; public uint Id; public UIntPtr WParam; public IntPtr LParam; public uint Time; public Point Position; public uint Private; }
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern IntPtr FindWindow(string name, string title);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll", SetLastError=true)] static extern IntPtr SetWinEventHook(uint first, uint last, IntPtr module, WinEventProc callback, uint process, uint thread, uint flags);
    [DllImport("user32.dll")] static extern bool UnhookWinEvent(IntPtr hook);
    [DllImport("user32.dll", SetLastError=true)] static extern bool PostMessage(IntPtr hwnd, uint message, UIntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll", SetLastError=true)] static extern bool PostThreadMessage(uint thread, uint message, UIntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] static extern void PostQuitMessage(int code);
    [DllImport("user32.dll")] static extern int GetMessage(out Message message, IntPtr hwnd, uint min, uint max);
    [DllImport("user32.dll")] static extern bool PeekMessage(out Message message, IntPtr hwnd, uint min, uint max, uint remove);
    [DllImport("user32.dll")] static extern bool TranslateMessage(ref Message message);
    [DllImport("user32.dll")] static extern IntPtr DispatchMessage(ref Message message);
    [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();

    public static void WaitForShownWindowAndClose(Process process) {
        // Window visibility follows Dart's listener registration and prevent-close
        // setup. Wait for that event instead of treating input-idle as app-ready.
        uint owner = GetCurrentThreadId();
        Message message;
        PeekMessage(out message, IntPtr.Zero, 0, 0, 0); // Create this thread's queue.
        bool requested = false;
        bool pumping = false;
        string failure = null;
        Action inspect = () => {
            if (requested || failure != null) return;
            IntPtr window = FindWindow("FLUTTER_RUNNER_WIN32_WINDOW", "ProtEnte");
            uint pid;
            GetWindowThreadProcessId(window, out pid);
            if (window == IntPtr.Zero || pid != process.Id || !IsWindowVisible(window)) return;
            // WM_CLOSE invokes the application's actual Windows quit path.
            if (PostMessage(window, 0x0010, UIntPtr.Zero, IntPtr.Zero)) requested = true;
            else failure = "Could not request normal window close.";
            if (pumping) PostQuitMessage(0);
        };
        WinEventProc callback = (hook, evt, hwnd, obj, child, thread, time) => inspect();
        IntPtr subscription = SetWinEventHook(0x8002, 0x8002, IntPtr.Zero, callback, (uint)process.Id, 0, 0);
        if (subscription == IntPtr.Zero) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        EventHandler exited = (sender, args) => PostThreadMessage(owner, 0x0012, UIntPtr.Zero, IntPtr.Zero);
        try {
            process.Exited += exited;
            process.EnableRaisingEvents = true;
            inspect(); // Also handle a window shown before the hook was installed.
            if (!requested && !process.HasExited) {
                pumping = true;
                int result;
                while ((result = GetMessage(out message, IntPtr.Zero, 0, 0)) > 0) {
                    TranslateMessage(ref message);
                    DispatchMessage(ref message);
                }
                if (result < 0) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            }
            if (failure != null) throw new Exception(failure);
            if (!requested) throw new Exception("Application exited before its ProtEnte window was shown.");
        } finally {
            process.Exited -= exited;
            UnhookWinEvent(subscription);
            GC.KeepAlive(callback);
        }
    }
}
'@
    $process = Start-Process -FilePath $installedExe -WindowStyle Hidden -PassThru
    try {
        if (-not $process.WaitForInputIdle()) { throw 'Application did not reach its native input loop.' }
        [ProtEnteSmokeWindow]::WaitForShownWindowAndClose($process)
        $verification.nativeWindowStartupVerified = $true
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
